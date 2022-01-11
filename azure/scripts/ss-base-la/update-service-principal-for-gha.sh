#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

: "$1" "$2" "$3"

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly REPO="ss-base-la"
readonly USAGE="gha-${REPO}"
../tools/update-sp-for-gha.sh "$1" "$2" "$3" "${USAGE}"
