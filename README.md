# keepalived_containers

[![actions](https://github.com/ednz-cloud/keepalived-containers/actions/workflows/build.yml/badge.svg)](https://github.com/ednz-cloud/keepalived-containers/actions)
[![dockerhub](https://img.shields.io/docker/pulls/ednxzu/keepalived.svg)](https://hub.docker.com/r/ednxzu/keepalived)

Repository for building keepalived container images.

## Quick Start

This image requires the kernel module ip_vs loaded on the host (modprobe ip_vs) and needs to run with :
 - `--cap-add=NET_ADMIN`
 - `--net=host`

```bash
docker run --cap-add=NET_ADMIN --net=host -d ednxzu/keepalived:latest
```

## Versions

All images are available on [Dockerhub](https://hub.docker.com/r/ednxzu/keepalived).

This repository builds all keepalived version **>2.0.0**, with a few exceptions.
Some versions have undocumented build dependencies, and since I have not found how to build them, they are skipped for now.

Included versions:
 - `2.2.3`
 - `2.2.4`
 - `2.2.7`
 - `2.2.8`
 - `2.3.0`
 - `2.3.1`
 - `2.3.2`
 - `2.3.3`
 - `2.3.4`

Excluded versions:
 - `2.2.0`
 - `2.2.1`
 - `2.2.2`
 - `2.2.5` (not an actual release)
 - `2.2.6`

If you know how any of these versions can be built, please feel free to submit a PR to add them to the build list.

Specific version tags `X.Y.Z`, as well as `X.Y`, `X` and `latest` are available and automatically updated on rebuild.

New images are automatically built every 15 days, in order to keep the base image up-to-date. New keepalived versions are automatically fetched from the [keepalived](https://github.com/acassen/keepalived) repository, and will be built either by me manually triggering a new build, or during the next scheduled build (every 15 days).

Since images are rebuilt from upstream alpine images, and compiled from source every time, I cannot guarantee immutability of the images (it is dependent on upstream alpine), but realistically, you should be fine treating them as immutable images :slightly_smiling_face:

## Architecture

This repository builds container images for both **amd64** and **arm64** architectures.
ARM64 builds were contributed by [nano9g](https://github.com/nano9g).

Multi-architecture manifests are published on Docker Hub, so pulling the image on supported platforms will automatically get the correct architecture variant.

## Setup

### Simple Setup

This image is made to be super easy to customize without having to rebuild it or do any gymnastic.

The following **environment variables** are available by default.


| Name                 | Description                                            | Required | Default                           |
|----------------------|--------------------------------------------------------|----------|-----------------------------------|
| `CONFIG`             | Path to the config file (keepalived.conf)              | No       | `/etc/keepalived/keepalived.conf` |
| `VRRP_INSTANCE`      | Name of the VRRP Instance of the container             | No       | `$HOSTNAME`                       |
| `INTERFACE`          | The interface to attach the virtual IP to              | No       | `eth0`                            |
| `UNICAST_SRC_IP`     | The source IP for unicast                              | No       | `ip of $INTERFACE`                |
| `UNICAST_PEERS`      | Comma-separated list of peers                          | No       | `NOT SET`                         |
| `STATE`              | Initial state of the keepalived instance               | No       | `BACKUP`                          |
| `ROUTER_ID`          | Unique identifier for the router                       | No       | `50`                              |
| `PRIORITY`           | Priority of the VRRP instance                          | No       | `100`                             |
| `ADVERTISE_INTERVAL` | Advertisement interval in seconds                      | No       | `1`                               |
| `VIRTUAL_IPS`        | Virtual IP addresses and associated interfaces         | No       | `192.168.2.100/32 dev $INTERFACE` |
| `PASSWORD`           | Authentication password for VRRP communication         | No       | `password`                        |
| `NOTIFY`             | Path to the script to be executed on state transitions | No       | `/notify.sh`                      |

These variables are used to configure keepalived instance, but in simple scenarios, most of them can be left untouched.

An example config to deploy a simple virtual IP would look like:

```bash
docker run --cap-add=NET_ADMIN \
--net=host \
-e INTERFACE=ens1 \
-e VIRTUAL_IPS="10.1.20.10" \
ednxzu/keepalived
```

### Bring your own template

This image uses a package called `envsubst` to render a working configuration file from a "template"

The initial configuration template looks like this:

```bash
[...]
vrrp_instance ${VRRP_INSTANCE} {
  interface ${INTERFACE}

  state ${STATE}
  virtual_router_id ${ROUTER_ID}
  priority ${PRIORITY}
  advert_int ${ADVERTISE_INTERVAL}
[...]
```

The entrypoint will simply look for and replace environment variables found within the template, which means that **you can make your own template** and use your own environment variables within it to render the exact configuration you need.

```bash
docker run --cap-add=NET_ADMIN \
--net=host \
-v "./keepalived.conf:/etc/keepalived/keepalived.conf"
-e INTERFACE=ens1 \
-e VIRTUAL_IPS="10.1.20.10" \
-e YOUR_VARIABLE=1337 \
ednxzu/keepalived
```

### Bring your own config

In the event that the entrypoint does not find any occurence of `${*}` within the file specified in `$CONFIG`, it will assume that the configuration does not need templating, and will simply try to run it as is.

This means that you can also bring your own configuration altogether, and forget about the environment variables.

```bash
docker run --cap-add=NET_ADMIN \
--net=host \
-v "./keepalived:/etc/keepalived"
ednxzu/keepalived
```

This way, you can add features that are not built-in to this image, like check scripts, etc...
