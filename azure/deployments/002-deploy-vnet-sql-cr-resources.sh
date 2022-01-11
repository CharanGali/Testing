#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

readonly SUBSCRIPTION_CODE=${1:-gcspre}
readonly REGION_CODE=${2:-japaneast}
readonly ENV_NAME=${3:-dev}
readonly APP_CODE=${4:-lacmn}

pushd $(dirname $0)

readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
function addPolicy () {
  bash ./../scripts/add-myself-to-key-vault-access-policy.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME}
}
function deletePolicy () {
  bash ./../scripts/remove-myself-to-key-vault-access-policy.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME}
}
trap "deletePolicy; popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS="\
  ${ENV_NAME} \
  ${REGION_CODE} \
  ${SUBSCRIPTION_CODE} \
  ${APP_CODE}
"

echo '----------- create virtual networks -----------'
bash ./../scripts/create-network-virtual-network.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- create private dns -----------'
bash ./../scripts/create-network-private-dns-zones.sh ${COMMON_DEPLOYMENT_OPTIONS}

addPolicy

echo '----------- create db for mysql servers -----------'
bash ./../scripts/create-db-for-mysql-server.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- update mysql server parameters -----------'
bash ./../scripts/update-mysql-parameters.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- create container registry -----------'
bash ./../scripts/create-container-registry.sh ${COMMON_DEPLOYMENT_OPTIONS}
