# keepalived-containers

[![build-keepalived](https://github.com/ednz-cloud/keepalived-containers/actions/workflows/build-keepalived.yml/badge.svg)](https://github.com/ednz-cloud/keepalived-containers/actions/workflows/build-keepalived.yml)
[![build-conntrackd](https://github.com/ednz-cloud/keepalived-containers/actions/workflows/build-conntrackd.yml/badge.svg)](https://github.com/ednz-cloud/keepalived-containers/actions/workflows/build-conntrackd.yml)

Container images for high-availability networking with keepalived and conntrackd.

## Images

| Image                                                                                                                 | Description                            | Documentation                            |
| --------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ---------------------------------------- |
| [![dockerhub](https://img.shields.io/docker/pulls/ednxzu/keepalived.svg)](https://hub.docker.com/r/ednxzu/keepalived) | VRRP-based failover and load balancing | [docs/keepalived.md](docs/keepalived.md) |
| [![dockerhub](https://img.shields.io/docker/pulls/ednxzu/conntrackd.svg)](https://hub.docker.com/r/ednxzu/conntrackd) | Connection tracking synchronization    | [docs/conntrackd.md](docs/conntrackd.md) |

## Quick Start

### keepalived

```bash
docker run --cap-add=NET_ADMIN --net=host \
  -e INTERFACE=eth0 \
  -e VIRTUAL_IPS="10.1.20.10" \
  -d ednxzu/keepalived:latest
```

### conntrackd

```bash
docker run --privileged --net=host \
  -e IPV4_DESTINATION_ADDRESS=192.168.1.2 \
  -d ednxzu/conntrackd:latest
```

## Architecture

Both images are built for **amd64** and **arm64** architectures and are automatically rebuilt every 15 days.

## License

See [LICENSE](LICENSE) for details.
