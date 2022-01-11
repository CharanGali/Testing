#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1" "$2"

readonly ENV_NAME=${1:?}
readonly MODULE_NAME=${2:?}
readonly REGION_CODE=${3:-"japaneast"}
readonly SUBSCRIPTION_CODE=${4:-"gcspre"}
readonly APP_CODE=${5:-"lacmn"}
readonly ROUTING_PATH=${6:-"/${MODULE_NAME}/*"}
readonly HTTP_SETTING_NAME=${7:-"http-setting-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}
readonly BACKEND_POOL_NAME=${8:-"backend-pool-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(../scripts/build-subscription-option.sh "${SUBSCRIPTION_CODE}")

if [[ ${MODULE_NAME} == la ]]; then
  # AKS nodeのPublic IPアドレス取得
  TARGET_NODE_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-node"
  # shellcheck disable=SC2086
  AKS_PIP_LIST=$(\
    az network public-ip list \
    ${SUBSCRIPTION_OPTION} \
    --resource-group "${TARGET_NODE_RG_NAME}" \
    --query [].ipAddress \
    --output json \
   | jq -M -c 'map(. + "/32")')

  # laはdps(=AKS)からのみアクセス可能
  IP_LIST="${AKS_PIP_LIST}"
elif [[ ${MODULE_NAME} == dps ]]; then
  # 共用のパラメータファイルよりSEN+SARDのIP帯を生成
  SEN_AND_SARD_IP_LIST=$(jq -M -c -s \
    '.[0].parameters.ipRules[] +
     .[1].parameters.ipRules[]
     | map(.value)' \
    ../parameters/sen-ip.json \
    ../parameters/sard-ip.json)

  # dpsはSEN+SARDからのみアクセス可能
  IP_LIST="${SEN_AND_SARD_IP_LIST}"
else
  echo "Invalid module name: ${MODULE_NAME}" 1>&2
  exit 1
fi

echo '----------- create additonal AGW WAF policies -----------'
../scripts/create-agw-waf-policies.sh \
  "${ENV_NAME}" \
  "${MODULE_NAME}" \
  "${IP_LIST}" \
  "${REGION_CODE}" \
  "${SUBSCRIPTION_CODE}" \
  "${APP_CODE}"

readonly RULE_NAME="path-based-rule-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"
readonly PATH_MAP_NAME="laapi-${ENV_NAME}-rule"
readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"
readonly WAF_NAME="wgf${SUBSCRIPTION_CODE}${ENV_NAME}${APP_CODE}${MODULE_NAME}waf${REGION_CODE}"
readonly WAF_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-wgf"

echo '----------- associate WAF policies with AGW -----------'
../scripts/associate-waf-policies-with-agw.sh \
  "${SUBSCRIPTION_CODE}" \
  "${ROUTING_PATH}" \
  "${HTTP_SETTING_NAME}" \
  "${BACKEND_POOL_NAME}" \
  "${RULE_NAME}" \
  "${PATH_MAP_NAME}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}" \
  "${WAF_NAME}" \
  "${WAF_RG_NAME}"

