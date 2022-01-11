#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# description
# ==========
# Remove the argument IP in the custom rule of App Gateway WAF.
#
# arguments
# ==========
#
# 1. SUBSCRIPTION_ID
#
# 2. WAF_RG_NAME
#    AppGateway WAF Resource Group Name
#
# 3. WAF_POLICY_NAME
#    AppGateway WAF PolicyName
################################################################################
: $1 $2 $3

readonly SUBSCRIPTION_ID=$1
readonly WAF_RG_NAME=$2
readonly WAF_POLICY_NAME=$3

# Custom Rule Delete to WAF Policy
az network application-gateway waf-policy custom-rule delete \
  --name FromGitHubThenAllow \
  --policy-name ${WAF_POLICY_NAME} \
  --resource-group ${WAF_RG_NAME} \
  --subscription ${SUBSCRIPTION_ID}
