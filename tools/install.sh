#!/bin/sh

# This script installs Keepalived for the given version
VERSION=$1

install_dependencies() {
  # Install base dependencies that are common across versions
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
}

download_keepalived() {
  echo "Downloading Keepalived version $VERSION..."
  curl -s -o keepalived.tar.gz -SL http://keepalived.org/software/keepalived-${VERSION}.tar.gz
  mkdir -p /build/keepalived
  tar -xzf keepalived.tar.gz --strip 1 -C /build/keepalived
}

build_keepalived() {
  cd /build/keepalived || exit 1
  ./build_setup

  # Set default configuration flags (without MKDIR_P)
  CONFIGURE_FLAGS="
    --disable-dynamic-linking
    --disable-dependency-tracking
    --enable-bfd
    --enable-json
    --enable-nftables
    --enable-snmp
    --enable-snmp-rfc
    --enable-regex
    --prefix=/usr
    --exec-prefix=/usr
    --bindir=/usr/bin
    --sbindir=/usr/sbin
    --sysconfdir=/etc
    --datadir=/usr/share
    --localstatedir=/var
    --mandir=/usr/share/man
  "

  # Customize configuration for specific versions
  if [ "$VERSION" = "2.3.2" ]; then
    apk add linux-headers bash
    sed -i 's/#include <linux\/if_ether.h>//' keepalived/vrrp/vrrp.c
    CONFIGURE_SHELL="/bin/bash" # Use bash for configure on version 2.3.2
  else
    CONFIGURE_SHELL="/bin/sh" # Default shell
  fi

  # Run configure with MKDIR_P set in the environment and the configuration flags
  MKDIR_P="/bin/mkdir -p" $CONFIGURE_SHELL ./configure $CONFIGURE_FLAGS

  make && make install
  strip /usr/sbin/keepalived
}

# Main script execution
install_dependencies
download_keepalived
build_keepalived
