#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHART_NAME="${1:-message-processor}"
REGISTRY_URL="${REGISTRY_URL:-oci://localhost:5001/charts}"
DIST_DIR="${REPO_ROOT}/dist"

mkdir -p "${DIST_DIR}"

echo "============================================================"
echo "  Packaging & Publishing Golden Path Helm Chart: ${CHART_NAME}"
echo "============================================================"

echo -e "\n📦 [1/2] Packaging chart ${CHART_NAME}..."
PACKAGE_OUTPUT=$(helm package "${REPO_ROOT}/charts/${CHART_NAME}" -d "${DIST_DIR}")
PACKAGE_FILE=$(echo "${PACKAGE_OUTPUT}" | awk '{print $NF}')

echo -e "\n🚀 [2/2] Pushing Helm OCI package to ${REGISTRY_URL}..."
helm push "${PACKAGE_FILE}" "${REGISTRY_URL}"

echo -e "\n✔ Chart published successfully to ${REGISTRY_URL}"
