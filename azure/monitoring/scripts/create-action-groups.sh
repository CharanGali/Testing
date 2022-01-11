#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

pushd $(dirname $0)
trap "popd" EXIT

az deployment group create \
  --name action-groups \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ./../templates/action-groups.json \
  --parameters env=${ENV_NAME} appCode=${APP_CODE} subscriptionCode=${SUBSCRIPTION_CODE}
