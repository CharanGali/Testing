#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit


: $1

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-main}

pushd $(dirname $0)
trap "popd" EXIT

readonly SERVICE_CODE="pip"
DEPLOYMENT_VERSION=$(git describe --always)

# Create Resource Group and get its name
RG_NAME=$(./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")
SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "network-public-ip-address" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/network-public-ip-address.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
