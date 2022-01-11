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

readonly SERVICE_CODE="pdnsz"
DEPLOYMENT_VERSION=$(git describe --always)

# Create Resource Group and get its name
RG_NAME=$(bash ./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")
SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "private-dns" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/network-private-dns-zones.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
