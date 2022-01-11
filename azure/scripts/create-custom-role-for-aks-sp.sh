#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# 概要
# ==========
# lacmnのAKSに設定するService Principalのためのカスタムロールを構築します。
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
#    e.g.) main
#
#
# 使用するARMテンプレート
# ==========
# * ../templates/lacmn/custom-role-for-aks-sp.json
#
# 使用するパラメータファイル
# ==========
# なし
#
################################################################################
: $1 $2 $3 $4

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd $(dirname $0)
trap "popd" EXIT

DEPLOYMENT_VERSION=$(git describe --always)
SUBSCRIPTION_OPTION=$(./../tools/build-subscription-option.sh "${SUBSCRIPTION_CODE}")

DEPLOYMENT_NAME="${SUBSCRIPTION_CODE}-${APP_CODE}-${ENV_NAME}-aks-sp-custom-role"
# Custom Roleはサブスクリプション単位で構築するリソース
# そのため az deployment group create ではなく、 az deployment sub create で構築する。
az deployment sub create \
  ${SUBSCRIPTION_OPTION} \
  --location ${REGION_CODE} \
  --name ${DEPLOYMENT_NAME} \
  --template-file ../../templates/lacmn/custom-role-for-aks-sp.json \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}
