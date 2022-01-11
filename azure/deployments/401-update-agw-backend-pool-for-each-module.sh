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
readonly BACKEND_POOL_NAME=${6:-"backend-pool-${SUBSCRIPTION_CODE}-${MODULE_NAME}-${ENV_NAME}"}
TARGET_IP_ADDRESS=${7:-"default"}

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"

if [ "${TARGET_IP_ADDRESS}" = "default" ]; then
  # k8sのservice名でEXTERNAL-IPを取得
  case "${MODULE_NAME}" in
  la|dps|ocsp)
    readonly TARGET_AKS_SERVICE_NAME="${MODULE_NAME}-express"
    TARGET_IP_ADDRESS=$(bash ./../scripts/get-aks-external-ip.sh \
      "${ENV_NAME}" \
      "${REGION_CODE}" \
      "${SUBSCRIPTION_CODE}" \
      "${APP_CODE}" \
      "${TARGET_AKS_SERVICE_NAME}" \
    )
    ;;
  *) exit 1 ;;
  esac
fi

bash ./../scripts/update-agw-backend-pool.sh \
  "${SUBSCRIPTION_CODE}" \
  "${BACKEND_POOL_NAME}" \
  "${TARGET_IP_ADDRESS}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}"
