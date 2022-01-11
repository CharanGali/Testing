#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}

pushd $(dirname $0)
trap "popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS="\
  ${ENV_NAME} \
  ${REGION_CODE} \
  ${SUBSCRIPTION_CODE} \
  ${APP_CODE}
"

echo '----------- create custom role for AKS service principal -----------'
./../scripts/create-custom-role-for-aks-sp.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- create service principal for AKS -----------'
./../scripts/create-service-principal-for-aks.sh ${ENV_NAME} ${SUBSCRIPTION_CODE} ${APP_CODE}

echo '----------- create managed clusters -----------'
./../scripts/create-container-service-managed-clusters.sh ${COMMON_DEPLOYMENT_OPTIONS}

echo '----------- assign custom role to aks service principal -----------'
./../scripts/assign-custom-role-to-aks-sp.sh ${ENV_NAME} ${SUBSCRIPTION_CODE} ${APP_CODE}
