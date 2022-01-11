#!/bin/bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx

pushd $(dirname $0)
trap "popd" EXIT

readonly TARGET_AKS_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-aks"
readonly TARGET_KV_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-kv"
readonly TARGET_NODE_RG_NAME="rg-${SUBSCRIPTION_CODE}-${ENV_NAME}-${APP_CODE}-node"

USAGE="logRetention"
STORAGE_ACCOUNT_DEPLOYMENT_NAME="storage-storage-accounts-${USAGE}"
STORAGE_ACCOUNT_RESOURCE_ID=$( \
  az deployment group show \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${MONITOR_RG_NAME} \
    --name ${STORAGE_ACCOUNT_DEPLOYMENT_NAME} \
    --query properties.outputs.storageAccountResourceId.value \
    --output tsv
)

readonly COMMON_PARAM="
  env=${ENV_NAME}
  location=${LOCATION}
  appCode=${APP_CODE}
  subscriptionCode=${SUBSCRIPTION_CODE}
"

# Kubernetes service
az deployment group create --verbose \
  --name "diagnostic-settings-kubernetes-service" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${TARGET_AKS_RG_NAME} \
  --template-file ./../templates/kubernetes-service.json \
  --parameters ${COMMON_PARAM}

# Key vaults
az deployment group create --verbose \
  --name "diagnostic-settings-key-vaults" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${TARGET_KV_RG_NAME} \
  --template-file ./../templates/key-vaults.json \
  --parameters ./../parameters/diagnostic-retention-policy.json \
  --parameters ${COMMON_PARAM} \
               storageAccountId=${STORAGE_ACCOUNT_RESOURCE_ID}

# Load balancers
az deployment group create --verbose \
  --name "diagnostic-settings-load-balancers" \
  ${SUBSCRIPTION_OPTION} \
  --resource-group ${TARGET_NODE_RG_NAME} \
  --template-file ./../templates/load-balancers.json \
  --parameters ${COMMON_PARAM}

# Network security group
readonly NETWORK_SECURITY_GROUP_NAMES=($( \
  az network nsg list \
  ${SUBSCRIPTION_OPTION} \
  --query [].name \
  --resource-group ${TARGET_NODE_RG_NAME} \
  --output tsv \
))
for i in ${!NETWORK_SECURITY_GROUP_NAMES[@]}; do
  NSG=${NETWORK_SECURITY_GROUP_NAMES[$i]}
  az deployment group create --verbose \
    --name "diagnostic-settings-network-security-group-${i}" \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${TARGET_NODE_RG_NAME} \
    --template-file ./../templates/network-security-group.json \
    --parameters ${COMMON_PARAM} \
                 networkSecurityGroupName=${NSG}
done

# Public IP Addresses
readonly PUBLIC_IP_ADDRESS_NAMES=($( \
  az network public-ip list \
  ${SUBSCRIPTION_OPTION} \
  --query [].name \
  --resource-group ${TARGET_NODE_RG_NAME} \
  --output tsv \
))
for i in ${!PUBLIC_IP_ADDRESS_NAMES[@]}; do
  PIA=${PUBLIC_IP_ADDRESS_NAMES[$i]}
  az deployment group create --verbose \
    --name "diagnostic-settings-public-ip-address-${i}" \
    ${SUBSCRIPTION_OPTION} \
    --resource-group ${TARGET_NODE_RG_NAME} \
    --template-file ./../templates/public-ip-addresses.json \
    --parameters ${COMMON_PARAM} \
                 publicIpAddressName=${PIA} \
                 targetRgName=${TARGET_NODE_RG_NAME}
done

function getNetworkInterfaceNames () {
  az network nic list \
    ${SUBSCRIPTION_OPTION} \
    --query "[].name" \
    --resource-group $1 \
    --output tsv
}

function createNetworkInterfaceSetting () {
  NETWORK_INTERFACE_NAMES=($1)
  for i in ${!NETWORK_INTERFACE_NAMES[@]}; do
    NIC=${NETWORK_INTERFACE_NAMES[$i]}
    az deployment group create --verbose \
      --name "diagnostic-settings-network-interface-${i}" \
      ${SUBSCRIPTION_OPTION} \
      --resource-group ${2} \
      --template-file ./../templates/network-interface.json \
      --parameters ${COMMON_PARAM} \
                   networkInterfaceName=${NIC}
  done
}

readonly KV_NETWORK_INTERFACE_NAMES=`getNetworkInterfaceNames ${TARGET_KV_RG_NAME}`

# Key Vault Network Interface
createNetworkInterfaceSetting "${KV_NETWORK_INTERFACE_NAMES[*]}" ${TARGET_KV_RG_NAME}
