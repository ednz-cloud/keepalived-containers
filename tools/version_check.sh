#!/bin/bash

EXCLUDED_TAGS="2.2.0 2.2.1 2.2.2 2.2.5 2.2.6"

# Make sure dependencies are installed
export DEBIAN_FRONTEND=noninteractive
sudo apt update
sudo apt install -y curl jq

function get_keepalived_tags() {
  curl --silent https://api.github.com/repos/acassen/keepalived/tags?per_page=100 | \
  jq -r '.[].name' | \
  sed 's/^v//' | \
  grep -vE "$(echo "$EXCLUDED_TAGS" | tr  ' ' '|')" | \
  sort -V -r
}

# function get_latest_minor_versions() {
#   local tags=("$@")
#   local latest_minor_versions=()
# 
#   local current_major=""
#   local current_minor=""
#   local current_latest=""
# 
#   for tag in "${tags[@]}"; do
#     local major_version=$(echo "$tag" | cut -d. -f1)
#     local minor_version=$(echo "$tag" | cut -d. -f2)
# 
#     if [[ "$major_version.$minor_version" != "$current_major.$current_minor" ]]; then
#       if [[ -n "$current_major" ]]; then
#         latest_minor_versions+=("$current_latest")
#       fi
#       current_major="$major_version"
#       current_minor="$minor_version"
#       current_latest="$tag"
#     else
#       local current_patch=$(echo "$current_latest" | cut -d. -f3)
#       local patch_version=$(echo "$tag" | cut -d. -f3)
#       if (( $patch_version > $current_patch )); then
#         current_latest="$tag"
#       fi
#     fi
#   done
# 
#   latest_minor_versions+=("$current_latest")
# 
#   echo "${latest_minor_versions[@]}"
# }

function get_latest_minor_versions() {
  local tags=("$@")
  declare -A latest_minor_versions

  for tag in "${tags[@]}"; do
    local major_version=$(echo "$tag" | cut -d. -f1)
    local minor_version=$(echo "$tag" | cut -d. -f2)
    local patch_version=$(echo "$tag" | cut -d. -f3)

    local current_latest=${latest_minor_versions["$major_version.$minor_version"]}
    if [[ -z "$current_latest" ]]; then
      latest_minor_versions["$major_version.$minor_version"]=$tag
    else
      local current_patch=$(echo "$current_latest" | cut -d. -f3)
      # Compare each component numerically
      if (( $major_version > $(echo "$current_latest" | cut -d. -f1) )) || \
         (( $major_version == $(echo "$current_latest" | cut -d. -f1) && $minor_version > $(echo "$current_latest" | cut -d. -f2) )) || \
         (( $major_version == $(echo "$current_latest" | cut -d. -f1) && $minor_version == $(echo "$current_latest" | cut -d. -f2) && $patch_version > $current_patch )); then
        latest_minor_versions["$major_version.$minor_version"]=$tag
      fi
    fi
  done

  # Convert the associative array to JSON format
  local json_output="{"
  for key in "${!latest_minor_versions[@]}"; do
    json_output+="\"$key\":\"${latest_minor_versions[$key]}\","
  done
  # Remove the trailing comma and close the JSON object
  json_output="${json_output%,*}}"
  echo "$json_output"
}

function get_latest_major_versions() {
  local tags=("$@")
  declare -A latest_major_versions

  for tag in "${tags[@]}"; do
    local major_version=$(echo "$tag" | cut -d. -f1)

    local current_latest=${latest_major_versions["$major_version"]}
    if [[ -z "$current_latest" || "$tag" > "$current_latest" ]]; then
      latest_major_versions["$major_version"]=$tag
    fi
  done

  # Convert the associative array to JSON format
  local json_output="{"
  for key in "${!latest_major_versions[@]}"; do
    json_output+="\"$key\":\"${latest_major_versions[$key]}\","
  done
  # Remove the trailing comma and close the JSON object
  json_output="${json_output%,*}}"
  echo "$json_output"
}


# function get_latest_major_versions() {
#   local tags=("$@")
#   local latest_major_versions=()
#   declare -A latest_for_major
# 
#   for tag in "${tags[@]}"; do
#     local major_version=$(echo "$tag" | cut -d. -f1)
# 
#     if [[ -z ${latest_for_major[$major_version]} || "$tag" > "${latest_for_major[$major_version]}" ]]; then
#       latest_for_major[$major_version]=$tag
#     fi
#   done
# 
#   for version in "${latest_for_major[@]}"; do
#     latest_major_versions+=("$version")
#   done
# 
#   echo "${latest_major_versions[@]}"
# }

function get_overall_latest_version() {
  local tags=("$@")
  local overall_latest=""

  for tag in "${tags[@]}"; do
    if [[ -z "$overall_latest" || "$tag" > "$overall_latest" ]]; then
      overall_latest="$tag"
    fi
  done

  echo "$overall_latest"
}

function main() {
  tags=($(get_keepalived_tags))

  # Get the latest version for each minor
  latest_minor_versions=$(get_latest_minor_versions "${tags[@]}")
  echo $latest_minor_versions
  # for version in ${latest_minor_versions[@]}; do
  #   echo "Latest for minor $(echo "$version" | cut -d. -f1-2): $version"
  # done

  # Get the latest version for each major
  latest_major_versions=$(get_latest_major_versions "${tags[@]}")
  echo $latest_major_versions
  # echo "Latest versions for each major:"
  # for version in ${latest_major_versions[@]}; do
  #   echo "Latest version for major $(echo "$version" | cut -d. -f1): $version"
  # done

  # Get the overall latest version
  overall_latest_version=$(get_overall_latest_version "${tags[@]}")
  echo $overall_latest_version
  # echo "Overall latest version is: $overall_latest_version"
}

main "$@"
