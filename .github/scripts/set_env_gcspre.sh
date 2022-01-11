#!/bin/bash

set +u -eo pipefail

# 命名規則 https://github.com/SonySemiconductorSolutions/ss-core-ops/wiki/Azure-Resource-%E5%91%BD%E5%90%8D%E8%A6%8F%E5%89%87

{
  echo "PREFIX=${BRANCH_NAME}"
  echo "APP_CODE=${APP_CODE}"
  echo "ENV_CODE=${ENV_CODE}"
  echo "SUBSCRIPTION_CODE=${SUBSCRIPTION_CODE}"
  echo "REGION_CODE=${REGION_CODE}"
  echo "AWS_SECRET_ACCESS_KEY=${AWS_SECRET_ACCESS_KEY}"
  echo "AWS_ACCESS_KEY_ID=${AWS_ACCESS_KEY_ID}"
  echo "CLUSTER_RG_NAME=rg-${SUBSCRIPTION_CODE}-${ENV_CODE}-${APP_CODE}-aks"
  echo "CLUSTER_NAME=aks-${SUBSCRIPTION_CODE}-${ENV_CODE}-${APP_CODE}-${REGION_CODE}"
  echo "MYSQL_NAME=mysql-${SUBSCRIPTION_CODE}-cmn-shared-${REGION_CODE}"
}  >> "$GITHUB_ENV"
