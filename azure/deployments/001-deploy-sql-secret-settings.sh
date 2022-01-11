#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

readonly SUBSCRIPTION_CODE=${1:-gcspre}
readonly REGION_CODE=${2:-japaneast}
readonly ENV_NAME=${3:-dev}
readonly APP_CODE=${4:-lacmn}

pushd $(dirname $0)

readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
./../scripts/add-myself-to-key-vault-access-policy.sh ${SUBSCRIPTION_CODE} ${SHARED_KV_RG_NAME}

function deletePolicy () {
  ./../scripts/remove-myself-to-key-vault-access-policy.sh ${SUBSCRIPTION_CODE} ${SHARED_KV_RG_NAME}
}

trap "deletePolicy; popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS="
  ${ENV_NAME}
  ${REGION_CODE}
  ${SUBSCRIPTION_CODE}
  ${APP_CODE}
"

echo '----------- set mysql admin user info to key vault -----------'
./../scripts/set-mysql-admin-user-info-to-kv.sh ${SUBSCRIPTION_CODE}
