#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

name=${1}
hostname=${2}

echo "##[group]Registry logs"
    docker logs "reconcilerio-registry-${name}"
echo "##[endgroup]"

echo "##[group]Remove hosts entry"
    sudo sed -i "/${hostname} # reconcilerio\/registry\/${name}/d" /etc/hosts
    cat /etc/hosts
echo "##[endgroup]"

echo "##[group]Stop registry"
    echo "Stopping container reconcilerio-registry-${name}"
    docker stop "reconcilerio-registry-${name}" > /dev/null
    echo "Deleting container reconcilerio-registry-${name}"
    docker rm "reconcilerio-registry-${name}" > /dev/null
echo "##[endgroup]"
