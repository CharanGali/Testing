#!/usr/bin/env bash
set -xeu
shopt -s inherit_errexit
set +v

readonly SUBSCRIPTION_CODE=${1:-""}

case "${SUBSCRIPTION_CODE}" in

  "dcsmdev" ) SUBSCRIPTION_NAME="SensingStationCore Dev" ;;
  "dcsmprd" ) SUBSCRIPTION_NAME="SensingStationCore Prd" ;;
  "gcsdev" ) SUBSCRIPTION_NAME="GlobalControlService Dev" ;;
  "sgcsprd" ) SUBSCRIPTION_NAME="GlobalControlService Prd" ;;
  "cameradev" ) SUBSCRIPTION_NAME="SmartCamera Global Control Service Dev" ;;
  "gcspre" ) SUBSCRIPTION_NAME="GlobalControlService Pre" ;;
  "gcsrls" ) SUBSCRIPTION_NAME="GlobalControlService Rls" ;;
  "gcssredev" ) SUBSCRIPTION_NAME="GlobalControlServiceSRE dev" ;;
  "camera" ) SUBSCRIPTION_NAME="SmartCamera Global Control Service Dev" ;;
  "sgcs" )   SUBSCRIPTION_NAME="GlobalControlService Prd" ;;
  "scsdev" ) SUBSCRIPTION_NAME="SmartCameraService dev" ;;
  * )   SUBSCRIPTION_NAME="" ;;
esac

# If SUBSCRIPTION_NAME is empty, you get a default subscription
SUBSCRIPTION_ID=$(az account show --subscription "${SUBSCRIPTION_NAME}" | jq -r .id)

echo ${SUBSCRIPTION_ID}