#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $4 $5

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=${2:-gcspre}
readonly APP_CODE=${3:-lacmn}
readonly ACM_ACCESS_KEY_ID=$4
readonly ACM_SECRET_ACCESS_KEY=$5

pushd $(dirname $0)
trap "popd" EXIT

# KeyVaultsへのシークレット登録
echo '----------- set secrets to key vault -----------'
./../scripts/set-key-vault-secrets-for-acm.sh \
  ${ENV_NAME} \
  ${SUBSCRIPTION_CODE} \
  ${APP_CODE} \
  ${ACM_ACCESS_KEY_ID} \
  ${ACM_SECRET_ACCESS_KEY}
