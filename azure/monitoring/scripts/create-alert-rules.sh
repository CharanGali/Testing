#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

pushd $(dirname $0)
trap "popd" EXIT

create_alert_rule () {
  local DEPLOY_NAME=$1
  local FILE_PATH=$2
  local LOCATION_PARAM=${3:-""}
  if [ -z $LOCATION_PARAM ]; then
    local PARAMETERS="env=${ENV_NAME} appCode=${APP_CODE} subscriptionCode=${SUBSCRIPTION_CODE}"
  else
    local PARAMETERS="env=${ENV_NAME} appCode=${APP_CODE} subscriptionCode=${SUBSCRIPTION_CODE} location=${LOCATION_PARAM}"
  fi
  az deployment group create --verbose \
    --name ${DEPLOY_NAME} \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${MONITOR_RG_NAME} \
    --template-file ${FILE_PATH} \
    --parameters ${PARAMETERS}
}

######################################
# resourceHealth alert rules
######################################
create_alert_rule \
  "alert-rules-resourceHealth-all-resources" \
  "./../templates/all-resources.json" \
  ${LOCATION}

######################################
# metrics alert rules
######################################
# AKS Recommended Metric Alerts
readonly AKS_RECOMMENDED_ALERT_TEMPLATES=(\
  "ContainerCPUPercentage" \
  "ContainerWorkingSetMemoryPercentage" \
  "NodeCPUPercentage" \
  "NodeDiskUsagePercentage" \
  "NodeNotReady" \
  "NodeWorkingSetMemoryPercentage" \
  "OOMKilledContainers" \
  "PodReadyPercentage" \
  "PodsInFailedState" \
  "PVUsagePercentage" \
  "RestartingContainerCount" \
  "StaleJobsCount" \
)
for FILE_NAME in "${AKS_RECOMMENDED_ALERT_TEMPLATES[@]}"; do
  create_alert_rule \
    "aks-recommended-alart-${FILE_NAME}" \
    "./../templates/aks/${FILE_NAME}.json"
done

create_alert_rule \
  "alert-rules-metrics-key-vault" \
  "./../templates/key-vault.json" \
  ${LOCATION}

######################################
# logSearch alert rules
######################################
create_alert_rule \
  "alert-rules-logSearch" \
  "./../templates/containerLog.json" \
  ${LOCATION}

######################################
# Storage Account alert rules
######################################
create_alert_rule \
  "alert-rules-metrics-blob-storage-logRetention-${ENV_NAME}-${APP_CODE}" \
  "./../templates/blob-storage-logRetention.json" \
  ${LOCATION}
