#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit


: "$1" "$2"

readonly ENV_NAME=$1
readonly MODULE_NAME=$2
readonly REGION_CODE=${3:-"japaneast"}
readonly SUBSCRIPTION_CODE=${4:-"gcspre"}
readonly APP_CODE=${5:-"lacmn"}
readonly HTTP_SETTING_NAME=${6:-"http-setting-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}
readonly BACKEND_PORT=${7:-"80"}
readonly OVERRIDE_BACKEND_PATH=${8:-"/"}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly CUSTOM_PROBE_NAME="${SUBSCRIPTION_CODE}-ladps-testprobe"
readonly TIMEOUT=240

readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"

./../scripts/update-agw-http-settings.sh \
  "${SUBSCRIPTION_CODE}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_PORT}" \
  "${OVERRIDE_BACKEND_PATH}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}" \
  "${CUSTOM_PROBE_NAME}" \
  "${TIMEOUT}"
