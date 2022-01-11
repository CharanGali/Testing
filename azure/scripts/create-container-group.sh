#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# overview
# ==========
# Build Container Instance Resources.
#
# argument
# ==========
#
# 1. Environment name
# e.g.) prod, dev, fdv-name ...
#
# 2. REGION_CODE (optional, japaneast if omitted)
# e.g.) japaneast, eastus
#
# 3. SUBSCRIPTION_CODE (optional, camera if omitted)
# e.g.) camera
#
# 4. APP_CODE (optional, main if omitted)
# e.g.) main
#
#
# ARM template to use
# ==========
# * ../templates/container-group.json
#
# Parameter file to use
# ==========
# * ../parameters/container-group.json
# none
#
################################################################################
: $1 $2 $3 $4

readonly ENV_NAME=$1
readonly REGION_CODE=$2
readonly SUBSCRIPTION_CODE=$3
readonly APP_CODE=$4

pushd $(dirname $0)
trap "popd" EXIT

readonly SERVICE_CODE="cg"
readonly USAGE="ocsptypeorm"
DEPLOYMENT_VERSION=$(git describe --always)

# Create Resource Group and get its name
RG_NAME=$(bash ./create-resource-group.sh ${ENV_NAME} ${REGION_CODE} ${SUBSCRIPTION_CODE} ${APP_CODE} ${SERVICE_CODE} | sed -ne "s/^RESOURCE_GROUP_NAME=\(.*\)$/\1/p")
SUBSCRIPTION_OPTION=$(bash ./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

az deployment group create \
  ${SUBSCRIPTION_OPTION} \
  --name "ocsp-dbmigration-container-group" \
  --resource-group ${RG_NAME} \
  --template-file ../templates/container-group.json \
  --parameters ../parameters/container-group.jsonc \
  --parameters \
    env=${ENV_NAME} \
    regionCode=${REGION_CODE} \
    appCode=${APP_CODE} \
    usage=${USAGE} \
    subscriptionCode=${SUBSCRIPTION_CODE} \
    deploymentVersion=${DEPLOYMENT_VERSION}