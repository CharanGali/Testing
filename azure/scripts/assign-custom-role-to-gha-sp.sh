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

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh ${SUBSCRIPTION_CODE})
SUBSCRIPTION_ID=$(bash ./get-subscription-id.sh ${SUBSCRIPTION_CODE})

USAGE="gha"
SERVICE_PRINCIPAL_NANE="sp-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${USAGE}"
SERVICE_PRINCIPAL_ID=$(\
  az ad sp list \
  --display-name ${SERVICE_PRINCIPAL_NANE} \
  --query "[?displayName=='${SERVICE_PRINCIPAL_NANE}'].objectId" \
  --output tsv \
)

DEPLOYMENT_NAME="${SUBSCRIPTION_CODE}-${APP_CODE}-${ENV_NAME}-gha-sp-custom-role"
CUSTOM_ROLE_DEPLOYMENT_OUTPUT=$(\
  az deployment sub show \
    ${SUBSCRIPTION_OPTION} \
    --name ${DEPLOYMENT_NAME} \
    --query properties.outputs \
)
CUSTOM_ROLE_ID=$(echo $CUSTOM_ROLE_DEPLOYMENT_OUTPUT | jq -r .customRoleId.value)

SCOPE_RESOURCE_GROUPS_OF_ROLE=(
  "/subscriptions/${SUBSCRIPTION_ID}"
)

for RG in "${SCOPE_RESOURCE_GROUPS_OF_ROLE[@]}"
do
  az role assignment create \
    ${SUBSCRIPTION_OPTION} \
    --assignee ${SERVICE_PRINCIPAL_ID} \
    --role ${CUSTOM_ROLE_ID} \
    --scope ${RG}
done
