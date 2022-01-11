#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1 $2

readonly SUBSCRIPTION_CODE=$1
readonly RG_NAME=$2

pushd $(dirname $0)
trap "popd" EXIT

SUBSCRIPTION_OPTION=$(./build-subscription-option.sh "${SUBSCRIPTION_CODE}")

# Delete resource group
az group delete ${SUBSCRIPTION_OPTION} --name ${RG_NAME} --yes
