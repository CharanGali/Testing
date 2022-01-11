#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# 概要
# ==========
# lacmn用のContainer Service / Managed Cluster を構築します。
#
# 引数
# ==========
#
# 1. 環境名
#    e.g.) prd, dev
#
# 2. REGION_CODE
#    e.g.) japaneast, eastus
#
# 3. SUBSCRIPTION_CODE
#    e.g.) gcspre
#
# 4. APP_CODE
#    e.g.) main, yt
#
#
# 使用するARMテンプレート
# ==========
# * ../templates/lacmn/container-service-managed-clusters.json
# * ../templates/lacmn/container-service-mc-agent-pools.json
#
# 使用するパラメータファイル
# ==========
# * ../parameters/lacmn/container-service-managed-clusters-secrets.json
# * ../parameters/lacmn/container-service-managed-clusters.json
#
# * ../parameters/lacmn/container-service-mc-agent-pools.json
#
################################################################################
: $1 $2 $3 $4

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd $(dirname $0)
trap "popd" EXIT

readonly SERVICE_CODE="aks"
DEPLOYMENT_VERSION=$(git describe --always)
SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# Create Resource Group and get its name
RG_NAME=$(bash ./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")

# Key Vault名の取得
readonly KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
KEY_VAULT_ID=$(bash ./get-key-vault-id.sh ${SUBSCRIPTION_CODE} ${KV_RG_NAME})
# パラメータファイルテンプレートを元にして、実際に使うパラメータJSONファイルを生成する
PARAM_JSON_TMP_FILE=$(mktemp)
sed -e "s:__TO_BE_RAPLACED_KEY_VAULT_ID__:${KEY_VAULT_ID}:g" \
  ../../parameters/lacmn/container-service-managed-clusters-secrets.json \
> ${PARAM_JSON_TMP_FILE}

SEN_IP_LIST=$(jq -c -M '.parameters.ipRules[] | map(.value)' < ../../parameters/sen-ip.json)

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "container-service-managed-clusters" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/container-service-managed-clusters.json \
  --parameters ${PARAM_JSON_TMP_FILE} \
  --parameters ../parameters/container-service-managed-clusters.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION} \
    senIpList=${SEN_IP_LIST}

# agent pool
az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "container-service-managed-clusters-agent-pool" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/container-service-mc-agent-pools.json \
  --parameters ../parameters/container-service-mc-agent-pools.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
