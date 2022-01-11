#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

: "$1" "$2" "$3" "$4"

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd $(dirname $0)
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")
readonly TARGET_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-mysql"
PARAMETERS_JSON=$(cat ./../parameters/mysql-parameters.json)
LENGTH=$(echo $PARAMETERS_JSON | jq length)

MYSQL_SERVER_NAMES=$( \
  az resource list \
    --resource-type 'Microsoft.DBforMySQL/flexibleServers' \
    --query "[].name" \
    ${SUBSCRIPTION_OPTION} \
    --resource-group "${TARGET_RG_NAME}" \
    --output tsv
)
for MYSQL_SERVER_NAME in "${MYSQL_SERVER_NAMES[@]}"; do
  for i in $( seq 0 $(($LENGTH - 1)) ); do
    PARAMETER_NAME=$(echo $PARAMETERS_JSON | jq -r .[$i].parameterName)
    VALUE=$(echo $PARAMETERS_JSON | jq -r .[$i].value)
    az mysql flexible-server parameter set \
      ${SUBSCRIPTION_OPTION} \
      --resource-group ${TARGET_RG_NAME} \
      --server ${MYSQL_SERVER_NAME} \
      --name ${PARAMETER_NAME} \
      --value ${VALUE}
  done
done
