#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2 $3

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
APP_CODE=lacmn

pushd $(dirname $0)
trap "popd" EXIT

TEMPLATE_DIR="./../templates/"
PARAMETER_DIR="./../parameters/"

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")
DEPLOYMENT_VERSION=$(git describe --always)

# Create resource group for key vault
readonly SERVICE_CODE="kv"
KV_RG_NAME=$(./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")

SECRET_OFFICER_OBJECT_IDS=$(\
  az ad sp list \
    --filter "\
      displayName eq 'sp-${SUBSCRIPTION_CODE}-cmn-main-gha' or \
      displayName eq 'sp-${SUBSCRIPTION_CODE}-cmn-main-gha-ss-base-dps' or \
      displayName eq 'sp-${SUBSCRIPTION_CODE}-cmn-main-gha-ss-base-la' or \
      displayName eq 'sp-${SUBSCRIPTION_CODE}-cmn-main-gha-ss-base-ocsp'
    " | jq -r '[.[].objectId]' \
)

RESULT_JSON='allow-ip.json'
SEN_SARD_IP_LIST=$(cat ../parameters/sen-ip.json ../parameters/sard-ip.json | jq -s \
  '.[0].parameters.ipRules.value +
   .[1].parameters.ipRules.value')
cat ../parameters/secroom-ip.json | jq ".parameters.ipRules.value |= .+${SEN_SARD_IP_LIST}" > ../parameters/${RESULT_JSON} 

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "key-vault" \
  --resource-group ${KV_RG_NAME} \
  --template-file ${TEMPLATE_DIR}/key-vault.json \
  --parameters ${PARAMETER_DIR}/key-vault.json \
  --parameters ./../parameters/allow-ip.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    appCode=${APP_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION} \
    secretOfficerObjectIds="${SECRET_OFFICER_OBJECT_IDS}"
set -vx
