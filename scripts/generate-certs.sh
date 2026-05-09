#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

name="${1}"
hostname="${2}"

cert_dir="${RUNNER_TEMP}/reconcilerio/registry/${name}"
work_dir="${cert_dir}/work"
if [ -d  "${cert_dir}" ] ; then
    echo "::error title=duplicate registry::another registry with the name \"${name}\" appears to be in use"
    exit 1
fi
mkdir -p "${work_dir}"


echo "##[group]Install cfssl"
    version="1.6.5"
    os="$(uname -s | tr '[:upper:]' '[:lower:]')"
    arch="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/aarch64/arm64/')"

    echo "Downloading https://github.com/cloudflare/cfssl/releases/download/v${version}/cfssl_${version}_${os}_${arch}"
    curl --fail -Lo ${work_dir}/cfssl "https://github.com/cloudflare/cfssl/releases/download/v${version}/cfssl_${version}_${os}_${arch}"
    echo "Downloading https://github.com/cloudflare/cfssl/releases/download/v${version}/cfssljson_${version}_${os}_${arch}"
    curl --fail -Lo ${work_dir}/cfssljson "https://github.com/cloudflare/cfssl/releases/download/v${version}/cfssljson_${version}_${os}_${arch}"
    chmod +x ${work_dir}/cfssl*
echo "##[endgroup]"

# Generate cfssl configs"
cat <<EOF > ${work_dir}/config.json
{
    "signing": {
        "default": {
            "expiry": "24h"
        },
        "profiles": {
            "intermediate": {
                "usages": [
                    "cert sign",
                    "crl sign"
                ],
                "ca_constraint": {
                    "is_ca": true,
                    "max_path_len": 0,
                    "max_path_len_zero": true
                },
                "expiry": "24h"
            },
            "server": {
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth"
                ],
                "expiry": "24h"
            },
            "client": {
                "usages": [
                    "signing",
                    "digital signature",
                    "key encipherment",
                    "client auth"
                ],
                "expiry": "24h"
            },
            "peer": {
                "usages": [
                    "signing",
                    "digital signature",
                    "key encipherment",
                    "client auth",
                    "server auth"
                ],
                "expiry": "24h"
            }
        }
    }
}
EOF
cat <<EOF > ${work_dir}/root-csr.json
{
    "CN": "Root CA",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "O": "${GITHUB_REPOSITORY}",
            "OU": "${GITHUB_WORKFLOW}"
        }
    ]
}
EOF
cat <<EOF > ${work_dir}/intermediate-csr.json
{
    "CN": "CA",
    "hosts": [
        ""
    ],
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "O": "${GITHUB_REPOSITORY}",
            "OU": "${GITHUB_WORKFLOW}"
        }
    ]
}
EOF
cat <<EOF > ${work_dir}/server-csr.json
{
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "O": "${GITHUB_REPOSITORY}",
            "OU": "${GITHUB_WORKFLOW}"
        }
    ]
}
EOF

echo "##[group]Generate CA"
    ${work_dir}/cfssl gencert \
        -initca ${work_dir}/root-csr.json \
    | ${work_dir}/cfssljson \
        -bare ${work_dir}/root-ca
    ${work_dir}/cfssl gencert \
        -ca ${work_dir}/root-ca.pem \
        -ca-key ${work_dir}/root-ca-key.pem \
        -config="${work_dir}/config.json" \
        -profile="intermediate" \
        ${work_dir}/intermediate-csr.json \
    | ${work_dir}/cfssljson \
        -bare ${work_dir}/signing-ca
    cat ${work_dir}/signing-ca.pem ${work_dir}/root-ca.pem > ${work_dir}/ca.pem
    echo ""
    ${work_dir}/cfssl certinfo -cert ${work_dir}/signing-ca.pem
echo "##[endgroup]"

echo "##[group]Generate cert"
    ${work_dir}/cfssl gencert \
        -ca ${work_dir}/signing-ca.pem \
        -ca-key ${work_dir}/signing-ca-key.pem \
        -config="${work_dir}/config.json" \
        -profile="server" \
        -hostname="${hostname},${name}" \
        ${work_dir}/server-csr.json \
    | ${work_dir}/cfssljson \
        -bare ${work_dir}/server
    echo ""
    ${work_dir}/cfssl certinfo -cert ${work_dir}/server.pem
echo "##[endgroup]"

echo "##[group]Install CA"
    # TODO handle non-ubuntu/debian systems
    # https://ubuntu.com/server/docs/security-trust-store
    sudo apt-get install -y ca-certificates
    sudo cp ${work_dir}/signing-ca.pem /usr/local/share/ca-certificates/reconcilerio-registry-${name}.crt
    sudo update-ca-certificates
echo "##[endgroup]"


mv "${work_dir}/ca.pem" "${cert_dir}/ca.pem"
mv "${work_dir}/server.pem" "${cert_dir}/server.pem"
mv "${work_dir}/server-key.pem" "${cert_dir}/server-key.pem"
rm -rf ${work_dir}

echo "tls-ca=${cert_dir}/ca.pem" >> "${GITHUB_OUTPUT}"
echo 'tls-ca-raw<<EOF' >> "${GITHUB_OUTPUT}"
cat ${cert_dir}/ca.pem >> "${GITHUB_OUTPUT}"
echo 'EOF' >> "${GITHUB_OUTPUT}"
