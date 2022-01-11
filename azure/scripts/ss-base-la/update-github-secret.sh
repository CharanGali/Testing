#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1"

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly REPO="ss-base-la"
readonly USAGE="gha-${REPO}"
readonly OWNER_REPO="SonySemiconductorSolutions/${REPO}"
../tools/update-github-secret.sh "$1" "${USAGE}" "${OWNER_REPO}"
