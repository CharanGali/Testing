#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

readonly SUBSCRIPTION_CODE=${1:-gcspre}
readonly REGION_CODE=${2:-japaneast}
readonly ENV_NAME=${3:-dev}
readonly APP_CODE=${4:-lacmn}

pushd "$(dirname "$0")"

# 共通Key Vaultのsecretの登録作業用にaccess policyに自分を登録する
readonly SHARED_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
bash ./../scripts/add-myself-to-key-vault-access-policy.sh "${SUBSCRIPTION_CODE}" "${SHARED_KV_RG_NAME}"

# 作業完了後にポリシーを削除するための関数
function deletePolicy () {
  bash ./../scripts/remove-myself-to-key-vault-access-policy.sh "${SUBSCRIPTION_CODE}" "${SHARED_KV_RG_NAME}"
}

trap "deletePolicy; popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS="
  ${ENV_NAME}
  ${REGION_CODE}
  ${SUBSCRIPTION_CODE}
  ${APP_CODE}
"

REPOS=(
  "ss-base-la"
  "ss-base-dps"
  "ss-base-ocsp"
)
for REPO in "${REPOS[@]}"
do
  echo "#################### ${REPO} ####################"

  echo '----------- create custom role for github action -----------'
  # shellcheck disable=SC2086
  bash "./../scripts/${REPO}/create-custom-role-for-gha-sp.sh" ${COMMON_DEPLOYMENT_OPTIONS}

  echo '----------- create service principal for github action -----------'
  bash "./../scripts/${REPO}/create-service-principal-for-gha.sh" "${ENV_NAME}" "${SUBSCRIPTION_CODE}" "${APP_CODE}"

  echo '----------- assign custom role to gha service principal -----------'
  bash "./../scripts/${REPO}/assign-custom-role-to-gha-sp.sh" "${ENV_NAME}" "${SUBSCRIPTION_CODE}" "${APP_CODE}"
done


