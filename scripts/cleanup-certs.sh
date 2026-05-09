#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

name="${1}"

echo "##[group]Uninstall CA"
    # TODO handle non-ubuntu/debian systems
    # https://ubuntu.com/server/docs/security-trust-store
    sudo rm /usr/local/share/ca-certificates/reconcilerio-registry-${name}.crt
    sudo update-ca-certificates --fresh
echo "##[endgroup]"

echo "##[group]Delete certificates"
    rm -rf -v "${RUNNER_TEMP}/reconcilerio/registry/${name}"
echo "##[endgroup]"
