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
require_env OCI_REGISTRY
require_env REGISTRY_USERNAME
require_env REGISTRY_PASSWORD

container_engine=""
if command -v podman >/dev/null 2>&1; then
  container_engine="podman"
elif command -v docker >/dev/null 2>&1; then
  container_engine="docker"
else
  printf 'missing required container engine: podman or docker\n' >&2
  exit 1
fi

image="${OCI_IMAGE}"
registry="${OCI_REGISTRY}"
source_sha="${GITHUB_SHA:-${GITEA_SHA:-$(git rev-parse HEAD)}}"
short_sha="$(printf '%s' "${source_sha}" | cut -c1-7)"
version_tag="${OCI_VERSION_TAG:-git-${short_sha}}"
alias_tag="${OCI_TAG_ALIAS:-}"

if [[ "${container_engine}" == "docker" ]]; then
  export DOCKER_CONFIG="${DOCKER_CONFIG:-/tmp/linein-passthrough-docker-config}"
  mkdir -p "${DOCKER_CONFIG}"
fi

printf '%s\n' "${REGISTRY_PASSWORD}" | "${container_engine}" login "${registry}" -u "${REGISTRY_USERNAME}" --password-stdin

"${container_engine}" build -f Containerfile -t "${image}:${version_tag}" .

"${container_engine}" push "${image}:${version_tag}"

digest="$("${container_engine}" image inspect --format '{{.Digest}}' "${image}:${version_tag}")"
if [[ -z "${digest}" || "${digest}" == "<no value>" ]]; then
  printf 'failed to resolve local image digest for %s:%s\n' "${image}" "${version_tag}" >&2
  exit 1
fi

immutable_digest_tag="sha256-${digest#sha256:}"
"${container_engine}" tag "${image}:${version_tag}" "${image}:${immutable_digest_tag}"
"${container_engine}" push "${image}:${immutable_digest_tag}"

if [[ -n "${alias_tag}" ]]; then
  "${container_engine}" tag "${image}:${version_tag}" "${image}:${alias_tag}"
  "${container_engine}" push "${image}:${alias_tag}"
fi

printf 'published immutable tags: %s, %s\n' "${version_tag}" "${immutable_digest_tag}"
if [[ -n "${alias_tag}" ]]; then
  printf 'published convenience alias: %s\n' "${alias_tag}"
fi
