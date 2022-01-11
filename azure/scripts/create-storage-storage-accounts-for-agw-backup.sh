#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit


: "$1" "$2" "$3" "$4"

readonly ENV_NAME=${1:?}
readonly REGION_CODE=${2:?}
readonly SUBSCRIPTION_CODE=${3:?}
readonly APP_CODE=${4:?}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly SERVICE_CODE="st-blob"
readonly USAGE="agw-backup"
DEPLOYMENT_VERSION=$(git describe --tags --always)
ST_RG_NAME=$(./create-resource-group.sh \
  "${ENV_NAME}" \
  "${REGION_CODE}" \
  "${SUBSCRIPTION_CODE}" \
  "${APP_CODE}" \
  "${SERVICE_CODE}-${USAGE}" | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")
read -ra SUBSCRIPTION_OPTION <<< \
  "$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")"

az deployment group create \
  "${SUBSCRIPTION_OPTION[@]}" \
  --name "storage-storage-accounts-agw-backup" \
  --resource-group "${ST_RG_NAME}" \
  --template-file ./../templates/storage-storage-accounts-for-agw-backup.json \
  --parameters ./../parameters/storage-storage-accounts-for-agw-backup.json \
  --parameters \
    env="${ENV_NAME}" \
    regionCode="${REGION_CODE}" \
    subscriptionCode="${SUBSCRIPTION_CODE}" \
    appCode="${APP_CODE}" \
    deploymentVersion="${DEPLOYMENT_VERSION}" \
    usage="${USAGE}"
