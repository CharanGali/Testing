#!/usr/bin/env bash
set -eux
shopt -s inherit_errexit
set +v
: $1 $2 $3

readonly ENV_NAME=$1
readonly APP_CODE=$2
readonly TYPE=$3
readonly CONFIDENTIALITY=${4:-""}
DEPLOYMENT_VERSION=$(git describe --always)

echo "--tags app=${APP_CODE} env=${ENV_NAME} type=${TYPE} confidentiality=${CONFIDENTIALITY} deploymentVersion=${DEPLOYMENT_VERSION}"