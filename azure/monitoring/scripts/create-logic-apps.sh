#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"

pushd $(dirname $0)

KEY_VAULT_ID=$(./../../scripts/get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})

OPSGENIE_API_KEY_PARAM_JSON_TMP_FILE=$(mktemp)
METRICS_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE=$(mktemp)
RESOURCEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE=$(mktemp)
SERVICEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE=$(mktemp)

sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       ../parameters/post_alert_opsgenie_api_key.json > ${OPSGENIE_API_KEY_PARAM_JSON_TMP_FILE}
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       ../parameters/metrics_opsgenie_endpoint.json > ${METRICS_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE}
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       ../parameters/resourcehealth_opsgenie_endpoint.json > ${RESOURCEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE}
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
       ../parameters/servicehealth_opsgenie_endpoint.json > ${SERVICEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE}

trap "rm -f ${OPSGENIE_API_KEY_PARAM_JSON_TMP_FILE} \
            ${METRICS_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE} \
            ${RESOURCEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE} \
            ${SERVICEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE} \
     ;popd" EXIT

# logSearch2Opsgenie
az deployment group create \
  --name "logic-app-logSearch2Opsgenie" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ./../templates/logSearch2Opsgenie.json \
  --parameters ${OPSGENIE_API_KEY_PARAM_JSON_TMP_FILE} \
  --parameters env=${ENV_NAME} \
               location=${LOCATION} \
               appCode=${APP_CODE} \
               subscriptionCode=${SUBSCRIPTION_CODE}

# resourceHealth2Opsgenie
az deployment group create \
  --name "logic-app-resourceHealth2Opsgenie" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ./../templates/resourceHealth2Opsgenie.json \
  --parameters ${RESOURCEHEALTH_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE} \
  --parameters env=${ENV_NAME} \
               location=${LOCATION} \
               appCode=${APP_CODE} \
               subscriptionCode=${SUBSCRIPTION_CODE}

# metrics2Opsgenie
az deployment group create \
  --name "logic-app-metrics2Opsgenie" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${MONITOR_RG_NAME} \
  --template-file ./../templates/metrics2Opsgenie.json \
  --parameters ${METRICS_OPSGENIE_ENDPOINT_PARAM_JSON_TMP_FILE} \
  --parameters env=${ENV_NAME} \
               location=${LOCATION} \
               appCode=${APP_CODE} \
               subscriptionCode=${SUBSCRIPTION_CODE}
