#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

pushd $(dirname $0)
trap "popd" EXIT

az deployment group create --verbose \
  --name enable-aks-monitoring-${APP_CODE} \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${TARGET_AKS_RG_NAME} \
  --template-file ./../templates/enable-aks-monitoring.json \
  --parameters env=${ENV_NAME} \
               appCode=${APP_CODE} \
               subscriptionCode=${SUBSCRIPTION_CODE} \
               targetRgName=${TARGET_AKS_RG_NAME}
