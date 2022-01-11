#!/usr/bin/env bash
echo -e "\n===== [$(readlink -f $0)] =====\n" 1>&2
shopt -s inherit_errexit

set +vx
VALUES_TO_BE_MASKED=${1:-${INPUT_PARAMETER_NAMES_TO_BE_MASKED}}

if [ -n "${VALUES_TO_BE_MASKED}" ]; then
  for PARAMETER_NAME in $(echo "${VALUES_TO_BE_MASKED}" | jq -r .[])
  do
    VALUE_TO_BE_MASKED=$(jq -r ".inputs.${PARAMETER_NAME}" ${GITHUB_EVENT_PATH})
    if [ -n "${VALUE_TO_BE_MASKED}" ]; then
      echo "hide ${PARAMETER_NAME}"
      echo "::add-mask::${VALUE_TO_BE_MASKED}"
    fi
  done
fi
set -vx
