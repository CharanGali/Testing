#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# description
# ==========
# Register the argument IP in the custom rule of App Gateway WAF.
#
# arguments
# ==========
#
# 1. IP_ADDRESS
#
# 2. SUBSCRIPTION_ID
#
# 3. WAF_RG_NAME
#    AppGateway WAF Resource Group Name
#
# 4. WAF_POLICY_NAME
#    AppGateway WAF PolicyName
################################################################################
: $1 $2 $3 $4

readonly IP_ADDRESS=$1
readonly SUBSCRIPTION_ID=$2
readonly WAF_RG_NAME=$3
readonly WAF_POLICY_NAME=$4

# Custom Rule Add to WAF Policy
az network application-gateway waf-policy custom-rule create \
  --action Allow \
  --name FromGitHubThenAllow \
  --policy-name ${WAF_POLICY_NAME} \
  --priority 15 \
  --resource-group ${WAF_RG_NAME} \
  --rule-type MatchRule \
  --subscription ${SUBSCRIPTION_ID}

# Custom Rule Match Condition Add to WAF Policy
az network application-gateway waf-policy custom-rule match-condition add \
  --resource-group ${WAF_RG_NAME} \
  --policy-name ${WAF_POLICY_NAME} \
  --name FromGitHubThenAllow \
  --operator IPMatch \
  --subscription ${SUBSCRIPTION_ID} \
  --values "${IP_ADDRESS}/32" \
  --match-variables RemoteAddr