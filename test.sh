#!/bin/bash -e

# Run Helm test
#
# This script does the following in sequence:
# - Runs a Helm install of a Conjur server
# - Runs a Helm test that deploys a test container that runs a
#   Bash Automated Test System (a.k.a. "Bats") test script that
#   confirms that the Conjur server's status page is active.
#
# Syntax:
#       ./test.sh <your-helm-test-args>
#
# Optional Environment Variables:
#   HELM_INSTALL_ARGS:    Additional arguments to pass to the `helm install`
#                         command beyond the standard arguments used below:
#                             --wait
#                             --timeout $HELM_INSTALL_TIMEOUT
#                             --set "dataKey=$dataKey"
#                         Defaults to empty string.
#   HELM_TEST_LOGGING:    Set to true to enable Helm test log collection.
#                         Defaults to false.
#   HELM_INSTALL_TIMEOUT: Helm install timeout. Defaults to `900s`.

# Command line arguments for this script are passed to `helm test`.
HELM_TEST_ARGS="$@"
HELM_INSTALL_ARGS=${HELM_INSTALL_ARGS:-""}
HELM_TEST_LOGGING=${HELM_TEST_LOGGING:-false}
HELM_INSTALL_TIMEOUT=${HELM_INSTALL_TIMEOUT:-900s}

# If Helm test logging is to be enabled, then we want to ensure that the
# test pod is not deleted until after Helm test has had a chance to display
# its logs.
if [ "$HELM_TEST_LOGGING" = "true" ]; then
  HELM_INSTALL_ARGS="${HELM_INSTALL_ARGS} --set test.deleteOnSuccess=false"
  HELM_TEST_ARGS="${HELM_TEST_ARGS} --logs"
fi

RELEASE_NAME="helm-chart-test-$(date -u +%Y%m%d-%H%M%S)"

function delete_release() {
  echo "=========================================="
  echo "Deleting Conjur Helm release $RELEASE_NAME"
  echo "=========================================="
  helm del "$RELEASE_NAME"
}

echo "======================================================="
echo "Installing Conjur OSS, waiting until server is ready..."
echo "======================================================="
dataKey="$(docker run --rm cyberark/conjur data-key generate)"
helm install --wait \
             --timeout $HELM_INSTALL_TIMEOUT \
             --set "dataKey=$dataKey" \
             $HELM_INSTALL_ARGS \
             "$RELEASE_NAME" \
             ./conjur-oss
trap delete_release EXIT

echo "=================================================="
echo "Running helm tests with arguments:"
echo "    $HELM_TEST_ARGS"
echo "=================================================="
helm test $HELM_TEST_ARGS "$RELEASE_NAME"

if  [ "$HELM_TEST_LOGGING" = "true" ]; then
  # Test pod log has been displayed, so it's safe to delete the test pod.
  kubectl delete pod -l release="$RELEASE_NAME"
fi
