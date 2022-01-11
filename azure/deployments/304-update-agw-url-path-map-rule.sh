#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1"

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-"japaneast"}
readonly SUBSCRIPTION_CODE=${3:-"gcspre"}
readonly APP_CODE=${4:-"lacmn"}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"

readonly ROUTING_PATH="/roleless/placeholder/for/initial/deployment"
readonly HTTP_SETTING_NAME="setting"
readonly BACKEND_POOL_NAME="aks-service"
readonly RULE_NAME="laapi-${ENV_NAME}-rule"

bash ./../scripts/update-agw-url-path-map.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ROUTING_PATH}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_POOL_NAME}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_POOL_NAME}" \
  "${RULE_NAME}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"

# 紐付けするリスナー名
readonly LISTENER_NAME="laapi-${ENV_NAME}-listener"
# 紐付けするデフォルトのPATH MAP名
readonly DEFAULT_URL_PATH_MAP_NAME="laapi-${ENV_NAME}-rule"

# デフォルトのルール作成
bash ./../../scripts/lacmn/upsert-agw-rules.sh \
  "${SUBSCRIPTION_CODE}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_POOL_NAME}" \
  "${DEFAULT_URL_PATH_MAP_NAME}" \
  "${RULE_NAME}" \
  "${LISTENER_NAME}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"

