# registry action  <!-- omit in toc -->

[![ci](https://github.com/reconcilerio/registry/actions/workflows/ci.yml/badge.svg)](https://github.com/reconcilerio/registry/actions/workflows/ci.yml)

Starts a secure, trusted OCI registry for a GitHub Actions workflow. The nuscenes of creating and trusting certificates, or allowing clients to run insecurely is avoided.

- [Usage](#usage)
- [Community](#community)
  - [Code of Conduct](#code-of-conduct)
  - [Communication](#communication)
  - [Contributing](#contributing)
- [Acknowledgements](#acknowledgements)
- [License](#license)

## Usage

See [action.yml](action.yml)

<!-- start usage -->
```yaml
- uses: actions/setup-node@v6
  with:
    # Optional hostname.
    # Host the registry will be exposed at. The registry is part of image references hosted on the registry.
    # Default: 'registry.local'
    hostname: ''

    # Optional port.
    # Port the registry is bound to on the host. If needed, change the port to avoid conflicts with other services.
    # Default: 80 (insecure), or 443 (secure)
    port: ''

    # Optional secure.
    # When true a TLS cert is used and the registry is accessed over HTTPS. When false the registry is accessed over HTTP. Most clients will require explicit approval to connect to an insecure registry. As the TLS cert is managed, it's strongly advised to run with security enabled.
    # Default: true
    secure: ''

    # Optional registry image.
    # Registry image that is run. Specify a different image to avoid pulling from Docker Hub, or pin to a specific image.
    # Default: 'registry:2'
    image: ''

    # Optional container name
    # Name of the Docker container running the registry. This value only needs to be specified if multiple registries are desired to run concurrently.
    # Default: 'reconcilerio-registry'
    name: ''

    # Optional TLS certificate.
    # The TLS certificate for a secure registry. If not specified a trusted certificate key pair is generated and used. Required when tls-key is also defined.
    # Default: ''
    tls-cert: ''

    # Optional TLS key.
    # The TLS key for a secure registry. If not specified a trusted certificate key pair is generated and used. Required when tls-cert is also defined.
    # Default: ''
    tls-key: ''
```
<!-- end usage -->

**Basic:**

```yaml
steps:
- uses: reconcilerio/registry@v1
- run: docker push registry.local/my/image
```

All input properties are optional. By default, the `registry:2` image is run on the local Docker daemon with port 443 mapped to it. A TLS certificate is generated and used on the registry, with the ca installed into the operating system so that local tools will trust the registry.

The registry is available at `registry.local`. An `/etc/hosts` entry is added to facilitate local access.

## Community

### Code of Conduct

The reconciler.io projects follow the [Contributor Covenant Code of Conduct](./CODE_OF_CONDUCT.md). In short, be kind and treat others with respect.

### Communication

General discussion and questions about the project can occur either on the Kubernetes Slack [#reconcilerio](https://kubernetes.slack.com/archives/C07J5G9NDHR) channel, or in the project's [GitHub discussions](https://github.com/orgs/reconcilerio/discussions). Use the channel you find most comfortable.

### Contributing

The reconciler.io wa8s project team welcomes contributions from the community. A contributor license agreement (CLA) is not required. You own full rights to your contribution and agree to license the work to the community under the Apache License v2.0, via a [Developer Certificate of Origin (DCO)](https://developercertificate.org). For more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

## Acknowledgements

The basic ideas that manifest in this action originated as a pile of bash scripts in the [Service Bindings for Kubernetes](https://github.com/servicebinding/runtime) runtime project, among others.

## License

Apache License v2.0: see [LICENSE](./LICENSE) for details.
