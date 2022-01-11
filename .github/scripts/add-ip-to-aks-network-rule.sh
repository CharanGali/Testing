#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# Description
# ==========
# Register the argument IP in the AKS Authorised IP Range. 
#
# Arguments
# ==========
#
# 1. Env Name
#    e.g.) dev, prd
#
# 2. REGION_CODE
#    e.g.) japaneast, eastus
#
# 3. SUBSCRIPTION_CODE
#    e.g.) gcspre
#
# 4. SUBSCRIPTION_ID
#
# 5. APP_CODE
#    e.g.) lacmn
#
# 6. IP_ADDRESS
#
################################################################################
: $1 $2 $3 $4 $5 $6

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly SUBSCRIPTION_ID=$4
readonly APP_CODE=$5
readonly IP_ADDRESS=$6

pushd $(dirname $0)

AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
AKS_CLUSTER_NAME="aks-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-${REGION_CODE}"
trap "popd" EXIT

AUTHORIZED_IP_RANGES=$(az aks show \
--subscription ${SUBSCRIPTION_ID} \
--resource-group ${AKS_RG_NAME} \
--name ${AKS_CLUSTER_NAME} \
--query apiServerAccessProfile.authorizedIpRanges \
)

NEW_AUTHORIZED_IP_RANGES=$(echo $AUTHORIZED_IP_RANGES | jq -r '. | join(",")'),${IP_ADDRESS}/32
az aks update \
--subscription ${SUBSCRIPTION_ID} \
--resource-group ${AKS_RG_NAME} \
--name ${AKS_CLUSTER_NAME} \
--api-server-authorized-ip-ranges ${NEW_AUTHORIZED_IP_RANGES}