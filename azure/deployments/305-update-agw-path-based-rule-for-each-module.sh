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
readonly ROUTING_PATH=${6:-"/${MODULE_NAME}/*"}
readonly HTTP_SETTING_NAME=${7:-"http-setting-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}
readonly BACKEND_POOL_NAME=${8:-"backend-pool-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}

pushd "$(dirname "$0")"
trap "popd" EXIT

# このスクリプトで追加・更新されるルール名
readonly RULE_NAME="path-based-rule-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"
readonly PATH_MAP_NAME="laapi-${ENV_NAME}-rule"

readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"

bash ./../scripts/update-agw-path-based-rule.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ROUTING_PATH}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_POOL_NAME}" \
  "${RULE_NAME}" \
  "${PATH_MAP_NAME}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"

