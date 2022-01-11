#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

readonly SUBSCRIPTION_CODE=${1:-gcspre}
readonly REGION_CODE=${2:-japaneast}
readonly ENV_NAME=${3:-dev}
readonly APP_CODE=${4:-lacmn}

readonly COMMON_DEPLOYMENT_OPTIONS="
  ${ENV_NAME}
  ${REGION_CODE}
  ${SUBSCRIPTION_CODE}
  ${APP_CODE}
"

echo '----------- create custom role for github action -----------'
bash ./../scripts/create-custom-role-for-gha-sp.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- create service principal for github action -----------'
bash ./../scripts/create-service-principal-for-gha.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- assign custom role to gha service principal -----------'
bash ./../scripts/assign-custom-role-to-gha-sp.sh ${COMMON_DEPLOYMENT_OPTIONS}
