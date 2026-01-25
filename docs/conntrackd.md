# conntrackd

Container image for running conntrackd, providing connection tracking synchronization for HA failover scenarios.

## Quick Start

```bash
docker run --privileged --net=host \
  -e IPV4_DESTINATION_ADDRESS=192.168.1.2 \
  -d ednxzu/conntrackd:latest
```

**Note:** conntrackd requires privileged mode for raw UDP socket access used in connection tracking synchronization.

## Environment Variables

| Name                       | Description                                    | Required | Default                              |
|----------------------------|------------------------------------------------|----------|--------------------------------------|
| `CONFIG`                   | Path to the config file                        | No       | `/etc/conntrackd/conntrackd.conf`    |
| `SYNC_MODE`                | Sync protocol (FTFW, NOTRACK, ALARM)           | No       | `FTFW`                               |
| `INTERFACE`                | Network interface for sync                     | No       | `eth0`                               |
| `IPV4_ADDRESS`             | Local IPv4 address                             | No       | auto-detect                          |
| `IPV4_DESTINATION_ADDRESS` | Peer IPv4 address                              | **Yes**  | -                                    |
| `SYNC_PORT`                | UDP port for sync                              | No       | `3780`                               |
| `HASH_SIZE`                | Connection hash table size                     | No       | `32768`                              |
| `HASH_LIMIT`               | Max tracked connections                        | No       | `131072`                             |
| `SOCKET_PATH`              | Unix socket path                               | No       | `/var/run/conntrackd/conntrackd.ctl` |

## Architecture

This repository builds container images for both **amd64** and **arm64** architectures.

Multi-architecture manifests are published on Docker Hub, so pulling the image on supported platforms will automatically get the correct architecture variant.

## Integration with Keepalived

To synchronize connection tracking during keepalived failovers, use the provided `notify-conntrackd.sh` script and share the conntrackd socket between containers.

### Architecture Diagram

```
┌─────────────────────────┐     ┌─────────────────────────┐
│  keepalived container   │     │  conntrackd container   │
│  (ednxzu/keepalived)    │     │  (ednxzu/conntrackd)    │
│                         │     │                         │
│  - keepalived daemon    │     │  - conntrackd daemon    │
│  - conntrack-tools      │     │  - entrypoint.sh        │
│  - notify-conntrackd.sh │     │                         │
│    calls conntrackd -C  │     │  Exposes:               │
│                         │     │  /var/run/conntrackd/   │
│  Mounts (shared vol):   │◄────│  conntrackd.ctl         │
│  /var/run/conntrackd/   │     │                         │
└─────────────────────────┘     └─────────────────────────┘
```

### Docker Compose Example

```yaml
services:
  conntrackd:
    image: ednxzu/conntrackd:latest
    network_mode: host
    privileged: true
    environment:
      - INTERFACE=eth0
      - IPV4_DESTINATION_ADDRESS=192.168.1.2
    volumes:
      - conntrackd-socket:/var/run/conntrackd

  keepalived:
    image: ednxzu/keepalived:latest
    network_mode: host
    cap_add:
      - NET_ADMIN
    environment:
      - INTERFACE=eth0
      - VIRTUAL_IPS=192.168.1.100
      - NOTIFY=/notify-conntrackd.sh
    volumes:
      - conntrackd-socket:/var/run/conntrackd:ro

volumes:
  conntrackd-socket:
```

### State Transitions

The `notify-conntrackd.sh` script handles state transitions:

- **MASTER**: Commits external cache to kernel, flushes caches, and resyncs
- **BACKUP**: Requests bulk sync from peer
- **FAULT**: Requests bulk sync from peer

## Bring your own config

Similar to the keepalived container, you can provide your own configuration file:

```bash
docker run --cap-add=NET_ADMIN \
--net=host \
-v "./conntrackd.conf:/etc/conntrackd/conntrackd.conf"
ednxzu/conntrackd
```

If the configuration file contains `${...}` patterns, it will be processed with `envsubst` for variable substitution.
