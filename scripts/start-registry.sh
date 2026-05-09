#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

name=${1}
hostname=${2}
port=${3}
image=${4}
secure=${5}
tls_cert=${6}
tls_key=${7}

echo "hostname=${hostname}" >> ${GITHUB_OUTPUT}

if [[ "${image}" == ":"* ]] ; then
    image="ghcr.io/reconcilerio/registry/docker.io/registry${image}"
fi

if [[ "${secure}" == "true" ]] ; then
    # run secure
    
    port="${port}"
    if [[ "${port}" == "0" ]]; then
        port="443"
        registry="${hostname}"
    else
        registry="${hostname}:${port}"
    fi
    echo "registry=${registry}" >> ${GITHUB_OUTPUT}

    echo "##[group]Starting secure registry: ${registry}"
        tls_cert="$(realpath "${tls_cert:-${RUNNER_TEMP}/reconcilerio/registry/${name}/server.pem}")"
        tls_key="$(realpath "${tls_key:-${RUNNER_TEMP}/reconcilerio/registry/${name}/server-key.pem}")"
        echo "Using TLS cert: ${tls_cert}"
        echo "Using TLS key: ${tls_key}"
        
        docker run -d \
            --restart=always \
            --name "reconcilerio-registry-${name}" \
            -v "${tls_cert}:/certs/server.pem:ro" \
            -v "${tls_key}:/certs/server-key.pem:ro" \
            -e "REGISTRY_HTTP_ADDR=0.0.0.0:${port}" \
            -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/server.pem \
            -e REGISTRY_HTTP_TLS_KEY=/certs/server-key.pem \
            -p "${port}:${port}" \
            "${image}"
    echo "##[endgroup]"

else
    # run insecure

    port="${port}"
    if [[ "${port}" == "0" ]] ; then
        port="80"
        registry="${hostname}"
    else
        registry="${hostname}:${port}"
    fi
    echo "registry=${registry}" >> ${GITHUB_OUTPUT}

    echo "##[group]Starting insecure registry: ${registry}"
        docker run -d \
            --restart=always \
            --name "reconcilerio-registry-${name}" \
            -e "REGISTRY_HTTP_ADDR=0.0.0.0:${port}" \
            -p "${port}:${port}" \
            "${image}"
    echo "##[endgroup]"

fi

echo "##[group]Add hosts entry: ${hostname} -> $(hostname -I | cut -d' ' -f1)"
    echo "$(hostname -I | cut -d' ' -f1) ${hostname} # reconcilerio/registry/${name}" | sudo tee -a /etc/hosts > /dev/null
    cat /etc/hosts
echo "##[endgroup]"
