#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1"

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}

pushd "$(dirname "$0")"
trap "popd" EXIT

# github actionsではkubectlをインストールする必要あり
if [ -n "${CI-}" ]; then
  az aks install-cli
fi

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

readonly CMN_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-main-kv"
CMN_KEY_VAULT_ID=$(bash ./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${CMN_KV_RG_NAME})
CMN_KEY_VAULT_NAME=$(basename "${CMN_KEY_VAULT_ID}")
get_secret_from_cmn_key_vault() {
  ./../../scripts/tools/get-key-vault-secret.sh "$1" "${SUBSCRIPTION_CODE}" "${CMN_KEY_VAULT_NAME}"
}

readonly MYSQL_HOST="mysql-${SUBSCRIPTION_CODE}-cmn-flexible-japaneast.mysql.database.azure.com"
readonly MYSQL_DATABASE_LA="${SUBSCRIPTION_CODE}_${ENV_NAME}_la_db"
readonly MYSQL_DATABASE_DPS="${SUBSCRIPTION_CODE}_${ENV_NAME}_dps_db"
readonly MYSQL_DATABASE_OCSP="${SUBSCRIPTION_CODE}_${ENV_NAME}_ocsp_db"
readonly MYSQL_USER_LA="${SUBSCRIPTION_CODE}_${ENV_NAME}_la_username"
readonly MYSQL_USER_DPS="${SUBSCRIPTION_CODE}_${ENV_NAME}_dps_username"
readonly MYSQL_USER_OCSP="${SUBSCRIPTION_CODE}_${ENV_NAME}_ocsp_username"

set +vx
MYSQL_ROOT_USERNAME="$(get_secret_from_cmn_key_vault 'mysqlAdminUsername')"
MYSQL_ROOT_PASSWORD="$(get_secret_from_cmn_key_vault 'mysqlAdminPassword')"

readonly KUBCTL_OPT="
  -i \
  --rm \
  --image=mysql:8.0 \
  --restart=Never \
  mysql-client -- \
  mysql --host=${MYSQL_HOST} --user=${MYSQL_ROOT_USERNAME} --password=${MYSQL_ROOT_PASSWORD}
"

# kubectlをaksに接続する
readonly CLUSTER_NAME="aks-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${REGION_CODE}"
readonly AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
# shellcheck disable=SC2086
az aks get-credentials ${SUBSCRIPTION_OPTION} \
  --resource-group "${AKS_RG_NAME}" \
  --name "${CLUSTER_NAME}" \
  --overwrite-existing

# shellcheck disable=SC2086
kubectl run ${KUBCTL_OPT} -vvv <<-EOD
  -- drop databases
  DROP DATABASE IF EXISTS ${MYSQL_DATABASE_LA};
  DROP DATABASE IF EXISTS ${MYSQL_DATABASE_DPS};
  DROP DATABASE IF EXISTS ${MYSQL_DATABASE_OCSP};

  -- drop users
  DROP USER IF EXISTS '${MYSQL_USER_LA}'@'%';
  DROP USER IF EXISTS '${MYSQL_USER_DPS}'@'%';
  DROP USER IF EXISTS '${MYSQL_USER_OCSP}'@'%';

  -- show databases
  SHOW DATABASES LIKE '${MYSQL_DATABASE_LA}';
  SHOW DATABASES LIKE '${MYSQL_DATABASE_DPS}';
  SHOW DATABASES LIKE '${MYSQL_DATABASE_OCSP}';
  -- show users
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_LA}';
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_DPS}';
  SELECT USER, HOST FROM mysql.user WHERE USER = '${MYSQL_USER_OCSP}';
EOD
