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

# このスクリプトで追加・更新されるリスナー名
readonly LISTENER_NAME="laapi-${ENV_NAME}-listener"

readonly AGW_NAME="agw-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-${REGION_CODE}"
readonly AGW_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-agw"

if [ "${ENV_NAME}" = "prd" ]; then
  HOST="laapi"
  HOST_NAMES="${HOST}.aitrios.sony-semicon.co.jp"
  SSL_CERT="cert-${SUBSCRIPTION_CODE}-aitrios"
else
  HOST="laapi-${ENV_NAME}"
  HOST_NAMES="${HOST}.sssiotpfs.com"
  SSL_CERT="${SUBSCRIPTION_CODE}SslCert"
fi

# Application GatewayのARMテンプレートで定義されている値
readonly FRONTEND_IP="appGatewayFrontendIP"
readonly FRONTEND_PORT="httpsPort"

# 紐付けするデフォルトのWAF policy名(050で作成済みのもの)
readonly CMN_WAF_NAME="wgf${SUBSCRIPTION_CODE}cmn${APP_CODE}waf${REGION_CODE}"
readonly CMN_WAF_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-wgf"

./../scripts/update-agw-listeners.sh \
  "${SUBSCRIPTION_CODE}" \
  "${LISTENER_NAME}" \
  "${FRONTEND_IP}" \
  "${FRONTEND_PORT}" \
  "${SSL_CERT}" \
  "${HOST_NAMES}" \
  "${AGW_NAME}" \
  "${AGW_RG_NAME}" \
  "${CMN_WAF_NAME}" \
  "${CMN_WAF_RG_NAME}"

