#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: $1

readonly ENV_NAME=$1
readonly REGION_CODE=${2:-japaneast}
readonly SUBSCRIPTION_CODE=${3:-gcspre}
readonly APP_CODE=${4:-lacmn}

pushd $(dirname $0)
trap "popd" EXIT

readonly COMMON_DEPLOYMENT_OPTIONS="
  ${ENV_NAME}
  ${REGION_CODE}
  ${SUBSCRIPTION_CODE}
  ${APP_CODE}
"

echo '----------- create sql database user -----------'
# shellcheck disable=SC2086
./../scripts/create-databases-and-users.sh ${COMMON_DEPLOYMENT_OPTIONS}
