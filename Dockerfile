# Build keepalived
FROM alpine:3.19.1 AS builder

RUN <<EOT
  apk --update-cache add \
    autoconf \
    automake \
    binutils \
    curl \
    file \
    file-dev \
    gcc \
    ipset \
    ipset-dev \
    iptables \
    iptables-dev \
    libip6tc \
    libip4tc \
    libmnl-dev \
    libnftnl-dev \
    libnl3 \
    libnl3-dev \
    make \
    musl-dev \
    net-snmp-dev \
    openssl \
    openssl-dev \
    pcre2 \
    pcre2-dev
EOT

ARG KEEPALIVED_VERSION=2.2.8
RUN <<EOT
  curl -s -o keepalived.tar.gz -SL http://keepalived.org/software/keepalived-${KEEPALIVED_VERSION}.tar.gz
  mkdir -p /build/keepalived
  tar -xzf keepalived.tar.gz --strip 1 -C /build/keepalived
EOT

WORKDIR /build/keepalived

RUN <<EOT
  ./build_setup
  ./configure \
    MKDIR_P='/bin/mkdir -p' \
    --disable-dynamic-linking \
    --disable-dependency-tracking \
    --enable-bfd \
    --enable-json \
    --enable-nftables \
    --enable-snmp \
    --enable-snmp-rfc \
    --enable-regex \
    --prefix=/usr \
    --exec-prefix=/usr \
    --bindir=/usr/bin \
    --sbindir=/usr/sbin \
    --sysconfdir=/etc \
    --datadir=/usr/share \
    --localstatedir=/var \
    --mandir=/usr/share/man
  make && make install
  strip /usr/sbin/keepalived
EOT

# Final stage
FROM alpine:3.19.1
LABEL maintainer "Bertrand Lanson"
LABEL description "Keepalived container"

RUN <<EOT
  apk --no-cache add \
    file \
    ipset \
    iptables \
    libip6tc \
    libip4tc \
    libmagic \
    libnl3 \
    libgcc \
    net-snmp \
    openssl \
    pcre2 \
    envsubst
  addgroup -S keepalived_script
  adduser -D -S -G keepalived_script keepalived_script
EOT

COPY --from=builder /usr/sbin/keepalived /usr/sbin/keepalived
COPY assets/keepalived.conf /etc/keepalived/keepalived.conf
COPY assets/notify.sh /notify.sh
COPY assets/entrypoint.sh /entrypoint.sh

CMD ["/bin/sh", "entrypoint.sh"]
