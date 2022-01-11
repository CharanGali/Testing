#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit


: $1 $2 $3 $4

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd $(dirname $0)
trap "popd" EXIT

readonly SERVICE_CODE="mysql"
DEPLOYMENT_VERSION=$(git describe --always)

# Create Resource Group and get its name
RG_NAME=$(./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")
SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${SHARED_KV_RG_NAME})

PARAM_JSON_TMP_FILE=$(mktemp)
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
  ../parameters/db-for-mysql-flexible-server.json \
> ${PARAM_JSON_TMP_FILE}

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "db-for-mysql-server" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/db-for-mysql-flexible-server.json \
  --parameters ${PARAM_JSON_TMP_FILE} \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    appCode=${APP_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
