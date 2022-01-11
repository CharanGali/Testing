#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2 $3 $4

export ENV_NAME=$1
export LOCATION=${2:-japaneast}
export SUBSCRIPTION_CODE=$3
export APP_CODE=${4:-main}

pushd $(dirname $0)
SUBSCRIPTION_OPTION=$(bash ../../scripts/build-subscription-option.sh "${SUBSCRIPTION_CODE}"); export SUBSCRIPTION_OPTION
export MONITOR_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-monitor"
export TARGET_AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"

trap "unset ENV_NAME \
      unset LOCATION \
      unset SUBSCRIPTION_CODE \
      unset APP_CODE \
      unset SUBSCRIPTION_OPTION \
      unset MONITOR_RG_NAME \
      unset TARGET_AKS_RG_NAME \
      ;popd" EXIT

# Create resource group
az group create \
  ${SUBSCRIPTION_OPTION} \
  --name ${MONITOR_RG_NAME} \
  --location ${LOCATION} \
  --tags app=${APP_CODE} env=${ENV_NAME} type=monitor

# Create log analytics workspace
az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "log-workspace" \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ../templates/log-analytics-workspace.json \
  --parameters \
    env=${ENV_NAME} \
    location=${LOCATION} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE}

bash ../scripts/create-log-retention-storage-account.sh
bash ../scripts/create-logic-apps.sh
bash ../scripts/create-action-groups.sh
bash ../scripts/enable-diagnostic-settings.sh
bash ../scripts/enable-aks-monitoring.sh
bash ../scripts/create-alert-rules.sh

