#!/usr/bin/env bash
set -eux
shopt -s inherit_errexit
set +v
readonly SUBSCRIPTION_CODE=${1:-""}

pushd $(dirname $0) > /dev/null
trap "popd > /dev/null" EXIT

SUBSCRIPTION_ID=$(bash ./get-subscription-id.sh ${SUBSCRIPTION_CODE})
echo "--subscription ${SUBSCRIPTION_ID}"