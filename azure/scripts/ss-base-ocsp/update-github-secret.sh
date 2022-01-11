#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f "$0")] =====\n" 1>&2
set -euvx
shopt -s inherit_errexit

################################################################################
# 概要
# ==========
# (共通Key Vaultにて登録済みの)
# Github Action用のService Principalのクレデンシャル情報を読み出し、
# GitHub Secretとして登録(=上書き更新)します。
#
# 引数
# ==========
#
# 1. SUBSCRIPTION_CODE
#    e.g.) gcspre, gcsrls
#
################################################################################
: "$1"

pushd "$(dirname "$0")"
trap "popd" EXIT

readonly REPO="ss-base-ocsp"
readonly USAGE="gha-${REPO}"
readonly OWNER_REPO="SonySemiconductorSolutions/${REPO}"
../tools/update-github-secret.sh "$1" "${USAGE}" "${OWNER_REPO}"
