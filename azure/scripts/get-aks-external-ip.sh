#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -eux
shopt -s inherit_errexit
set +v

: $1 $2 $3 $4 $5

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4
readonly SERVICE_NAME=$5

pushd $(dirname $0) > /dev/null
trap "popd > /dev/null" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")
AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
CLUSTER_NAME="aks-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${REGION_CODE}"

# github actionsではkubectlをインストールする必要あり
if [ -n "${CI-}" ]; then
  az aks install-cli
fi

az aks get-credentials ${SUBSCRIPTION_OPTION} \
  --resource-group "${AKS_RG_NAME}" \
  --name "${CLUSTER_NAME}" \
  --overwrite-existing > /dev/null

EXTERNAL_IP=$(kubectl get services "${SERVICE_NAME}" -o json | jq -r .status.loadBalancer.ingress[0].ip)

echo ${EXTERNAL_IP}
