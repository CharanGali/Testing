#!/bin/bash

set -euo pipefail

# 命名規則 https://github.com/SonySemiconductorSolutions/ss-core-ops/wiki/Azure-Resource-%E5%91%BD%E5%90%8D%E8%A6%8F%E5%89%87

{
  echo "PREFIX=${BRANCH_NAME}"
  echo "APP_CODE=${APP_CODE}"
  echo "ENV_CODE=${ENV_CODE}"
  echo "SUBSCRIPTION_CODE=${SUBSCRIPTION_CODE}"
  echo "REGION_CODE=${REGION_CODE}"
  echo "RG_NAME=rg-${APP_CODE}-${SERVICE_CODE}-${ENV_CODE}"
  echo "KV_RG_NAME=rg-${APP_CODE}-kv-${ENV_CODE}"
  echo "EXPRESS_IP_NAME=pip-${APP_CODE}-${SERVICE_CODE}-express-${REGION_CODE}"
  echo "LOG_ANALYTICS_NAME=log-${SUBSCRIPTION_CODE}-common-${ENV_CODE}"
  echo "DEPLOYMENT_VERSION=$(git describe)"
  echo "CLUSTER_RG_NAME=rg-${APP_CODE}-aks-node-${ENV_CODE}"
  echo "CLUSTER_NAME=aks-${APP_CODE}-${ENV_CODE}-${REGION_CODE}"
  echo "AKS_NAME=aks-${APP_CODE}-${ENV_CODE}-${REGION_CODE}"
  echo "AKSVNET=vnet-${APP_CODE}-${SERVICE_CODE}-${ENV_CODE}-${REGION_CODE}"
  echo "AKSSUBNET=snet-${APP_CODE}-aks-${ENV_CODE}-${REGION_CODE}"
  echo "MYSQL_NAME=mysql-${SUBSCRIPTION_CODE}-${APP_CODE}-${ENV_CODE}-${REGION_CODE}"
}  >> "$GITHUB_ENV"
