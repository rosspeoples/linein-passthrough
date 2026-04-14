#!/usr/bin/env bash

set -euo pipefail

require_env() {
  local name="$1"
  if [[ -z "${!name:-}" ]]; then
    printf 'missing required environment variable: %s\n' "$name" >&2
    exit 1
  fi
}

require_env OCI_IMAGE
require_env OCI_REGISTRY_USERNAME
require_env OCI_REGISTRY_TOKEN

image="${OCI_IMAGE}"
default_tag="${GITHUB_REF_NAME:-main}"
version_tag="${OCI_VERSION_TAG:-${default_tag}}"
latest_tag="${OCI_LATEST_TAG:-latest}"

printf '%s\n' "${OCI_REGISTRY_TOKEN}" | podman login ghcr.io -u "${OCI_REGISTRY_USERNAME}" --password-stdin

podman build -f Containerfile -t "${image}:${version_tag}" .

if [[ "${default_tag}" == "main" ]]; then
  podman tag "${image}:${version_tag}" "${image}:${latest_tag}"
  podman push "${image}:${latest_tag}"
fi

podman push "${image}:${version_tag}"
