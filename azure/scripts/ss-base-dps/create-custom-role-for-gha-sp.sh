#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit


: "$1" "$2" "$3" "$4"

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd "$(dirname "$0")"
trap "popd" EXIT

DEPLOYMENT_VERSION=$(git describe --always)
SUBSCRIPTION_OPTION=$(bash ../build-subscription-option.sh "${SUBSCRIPTION_CODE}")

readonly REPO="ss-base-dps"
DEPLOYMENT_NAME="${SUBSCRIPTION_CODE}-${APP_CODE}-${ENV_NAME}-gha-sp-custom-role-${REPO}"

az deployment sub create \
  ${SUBSCRIPTION_OPTION} \
   --location "${REGION_CODE}" \
  --name "${DEPLOYMENT_NAME}" \
  --template-file "../../templates/${REPO}/custom-role-for-gha-sp.json" \
  --parameters \
    env="${ENV_NAME}" \
    regionCode="${REGION_CODE}" \
    appCode="${APP_CODE}" \
    subscriptionCode="${SUBSCRIPTION_CODE}" \
    deploymentVersion="${DEPLOYMENT_VERSION}"
