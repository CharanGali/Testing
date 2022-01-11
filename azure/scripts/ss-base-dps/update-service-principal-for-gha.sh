#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# 概要
# ==========
# Github Action用のService Principalを更新します。
# また、更新されたクレデンシャル情報をKey Vaultに登録します。
#
# 引数
# ==========
#
# 1. 環境名
#    e.g.) cmn
#
# 2. SUBSCRIPTION_CODE
#    e.g.) gcspre, gcsrls
#
# 3. APP_CODE
#    e.g.) main
#
################################################################################
: "$1" "$2" "$3"

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly REPO="ss-base-dps"
readonly USAGE="gha-${REPO}"
../tools/update-sp-for-gha.sh "$1" "$2" "$3" "${USAGE}"
