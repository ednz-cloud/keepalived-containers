#!/bin/bash

EXCLUDED_TAGS="2.2.0 2.2.1 2.2.2 2.2.5 2.2.6"
REGEX_VERSION="^2\.(2|[3-9]|[1-9][0-9])\.[0-9]+$"

function get_keepalived_tags() {
  curl --silent https://api.github.com/repos/acassen/keepalived/tags?per_page=100 |
    jq -r '.[].name' |
    sed 's/^v//' |
    grep -E "$REGEX_VERSION" |
    grep -vE "$(echo "$EXCLUDED_TAGS" | tr ' ' '|')" |
    sort -V -r |
    tr '\n' ', ' |
    sed 's/,$//'
}

echo $(get_keepalived_tags)
