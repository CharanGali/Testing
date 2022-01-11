#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -eux
shopt -s inherit_errexit
set +v

: $1 $2 $3 $4 $5

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4
readonly SERVICE_CODE=$5
readonly USAGE=${6:-""}

pushd $(dirname $0)
trap "popd" EXIT

if [ -z "${USAGE}" ]; then
  # naming rule: rg-{Subscription}-{Environment}-{Application}-{Service}
  RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${SERVICE_CODE}"
else
  # naming rule: rg-{Subscription}-{Environment}-{Application}-{Service}-{Usage}
  RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${SERVICE_CODE}-${USAGE}"
fi

SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")
TAGS_OPTION=$(bash ./build-tags-option.sh "${ENV_NAME}" "${APP_CODE}" "infra" "")

# Create resource group
az group create \
  ${SUBSCRIPTION_OPTION} \
  ${TAGS_OPTION} \
  --name ${RG_NAME} \
  --location ${REGION_CODE}

echo "RESOURCE_GROUP_NAME=${RG_NAME}"