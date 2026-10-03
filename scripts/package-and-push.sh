#!/usr/bin/env bash
# Package a golden chart and, only if its version is not yet released, push it to GHCR.
# Releases normally happen in CI (.github/workflows/release.yaml). This script follows the same rule
# (2026-10-03 Step 0.7, L2-1): a released version is never pushed again. If the version exists, the
# packaged content is compared and the script stops; any registry error other than "not found" also
# stops it (fail closed). Bump `version` in Chart.yaml to release a change.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_NAME="${1:-queue-backed-service}"
REGISTRY_URL="${REGISTRY_URL:-oci://ghcr.io/brunobml/charts}"
DIST_DIR="${REPO_ROOT}/dist"
CHART_DIR="${REPO_ROOT}/charts/${CHART_NAME}"

mkdir -p "${DIST_DIR}"
version=$(helm show chart "${CHART_DIR}" | awk '/^version:/ {print $2; exit}')
[[ -n "$version" ]] || { echo "✘ cannot read version from ${CHART_DIR}/Chart.yaml" >&2; exit 1; }

echo "============================================================"
echo "  Packaging Golden Path Helm Chart: ${CHART_NAME} ${version}"
echo "============================================================"
pkg=$(helm package "${CHART_DIR}" -d "${DIST_DIR}" | awk '{print $NF}')

tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
set +e
pull_err=$(helm pull "${REGISTRY_URL}/${CHART_NAME}" --version "${version}" -d "${tmp}" 2>&1 >/dev/null)
pull_rc=$?
set -e
if (( pull_rc == 0 )); then
  mkdir -p "$tmp/local" "$tmp/remote"
  tar -xzf "$pkg" -C "$tmp/local"; tar -xzf "${tmp}/${CHART_NAME}-${version}.tgz" -C "$tmp/remote"
  if diff -r -q "$tmp/local" "$tmp/remote" >/dev/null; then
    echo "✔ ${CHART_NAME}:${version} is already released with identical content; nothing to push."
    exit 0
  fi
  echo "✘ ${CHART_NAME}:${version} is already released with DIFFERENT content. Bump 'version' in Chart.yaml." >&2
  exit 1
elif [[ "$pull_err" == *": not found"* ]]; then
  echo "🚀 ${CHART_NAME}:${version} is new; pushing to ${REGISTRY_URL}..."
  helm push "$pkg" "${REGISTRY_URL}"
  echo "✔ Chart published to ${REGISTRY_URL}"
else
  echo "✘ cannot tell whether ${CHART_NAME}:${version} exists (helm pull rc=${pull_rc}); refusing to push: ${pull_err}" >&2
  exit 1
fi
