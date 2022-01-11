#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx -o pipefail
shopt -s inherit_errexit

: "$1"

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=${2:-"gcspre"}
readonly APP_CODE=${3:-"lacmn"}

pushd "$(dirname "$0")"
trap "popd" EXIT

if [ "${APP_CODE}" = "lacmn" ]; then
  if [ "${ENV_NAME}" = "prd" ]; then
    DNS_ZONE="aitrios.sony-semicon.co.jp"
    SUB_DOMAIN="laapi"
    # TODO: PRDのDNSのサブスクリプション, RGが未決
    DNS_SUBSCRIPTION_CODE="gcssredev" # TBD
    DNS_RG_NAME="rg-gcssredev-cmn-dns" # TBD
  else
    DNS_ZONE="sssiotpfs.com"
    SUB_DOMAIN="laapi-${ENV_NAME}"
    DNS_SUBSCRIPTION_CODE="dcsmdev"
    DNS_RG_NAME="qas-ssiotpfs-com-domain"
  fi
else
  echo "There is no definition of DNS related information."
  exit 1
fi

# Public IPアドレス取得
SUBSCRIPTION_OPTION=$(./../scripts/build-subscription-option.sh "${SUBSCRIPTION_CODE}")
PIP_RG_NAME="rg-${SUBSCRIPTION_CODE}-cmn-${APP_CODE}-pip"
# shellcheck disable=SC2086
PUBLIC_IP=$(\
  az network public-ip list \
  ${SUBSCRIPTION_OPTION} \
  --resource-group "${PIP_RG_NAME}" \
  --query [].ipAddress \
  --output tsv \
)

./../scripts/update-public-ip-to-dns.sh \
  "${DNS_ZONE}" \
  "${SUB_DOMAIN}" \
  "${PUBLIC_IP}" \
  "${DNS_SUBSCRIPTION_CODE}" \
  "${DNS_RG_NAME}"
