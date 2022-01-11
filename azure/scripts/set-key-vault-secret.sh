#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -eu
# サブシェル内でのエラーでも終了するようにオプションを設定（Bash 4.4+ required）
shopt -s inherit_errexit
set +vx

: "$1" "$2" "$3" "$4"

readonly SECRET_NAME=$1
readonly SECRET_VALUE=$2
readonly SUBSCRIPTION_CODE=$3
readonly KEY_VAULT_NAME=$4

pushd "$(dirname "$0")"
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# shellcheck disable=SC2086
az keyvault secret set \
  ${SUBSCRIPTION_OPTION} \
  --vault-name "${KEY_VAULT_NAME}" \
  --name "${SECRET_NAME}" \
  --value "${SECRET_VALUE}"
