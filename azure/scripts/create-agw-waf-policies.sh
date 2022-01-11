#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit


readonly ENV_NAME=${1:-dev}
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}

pushd $(dirname $0)
trap "popd" EXIT

readonly SERVICE_CODE="wgf"
DEPLOYMENT_VERSION=$(git describe --always)
SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# Create Resource Group and get its name
RG_NAME=$(./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "waf-policy" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/agw-waf-policies.json \
  --parameters ../parameters/agw-waf-policies.jsonc \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
