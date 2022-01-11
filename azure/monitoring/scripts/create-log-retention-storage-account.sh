#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

pushd $(dirname $0)
trap "popd" EXIT

DEPLOYMENT_VERSION=$(git describe --tags --always)

USAGE="logRetention"
DEPLOYMENT_NAME="storage-storage-accounts-${USAGE}"
az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "${DEPLOYMENT_NAME}" \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ./../templates/log-retention-storage-account.json \
  --parameters ./../../parameters/sen-ip.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${LOCATION} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    appCode=${APP_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION} \
    usage=${USAGE}
