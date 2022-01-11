#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1

readonly ENV_NAME=$1
readonly SUBSCRIPTION_CODE=${2:-gcspre}
readonly APP_CODE=${3:-lacmn}

pushd $(dirname $0)
trap "popd" EXIT

echo '----------- create service principals for scapi -----------'
./../scripts/create-service-principal-for-lacmn.sh ${ENV_NAME} ${SUBSCRIPTION_CODE} ${APP_CODE}

