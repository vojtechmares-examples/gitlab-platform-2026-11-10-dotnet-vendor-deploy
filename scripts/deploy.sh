#!/usr/bin/env bash
# shellcheck disable=SC2029  # the variables are meant to expand on this side, into the remote command
# Deploy one environment: copy its Quadlet file to the rootless Podman account on the server and restart the
# generated unit.   scripts/deploy.sh staging|production
#
# Quadlet: systemd's generator turns ~/.config/containers/systemd/<name>.container into <name>.service of the user's
# systemd instance. Pulling the image is part of starting the unit (Podman pulls what is missing).
set -euo pipefail

ENVIRONMENT="${1:?usage: deploy.sh staging|production}"
NAME="dotnet-vendor-${ENVIRONMENT}"
FILE="quadlet/${ENVIRONMENT}/${NAME}.container"
URL="https://${NAME}.${EXAMPLES_DOMAIN:?EXAMPLES_DOMAIN is not set}"
: "${VENDOR_REGISTRY_USER:?CI/CD variable VENDOR_REGISTRY_USER (deploy token of the vendor project) is not set}"
: "${VENDOR_REGISTRY_TOKEN:?CI/CD variable VENDOR_REGISTRY_TOKEN is not set}"

IMAGE="$(sed -n 's/^Image=//p' "${FILE}")"
VERSION="${IMAGE##*:}"
echo "==> ${NAME}: ${IMAGE}"

echo "==> log in to the vendor's registry with its read-only deploy token (kept in ~/.config/containers/auth.json)"
printf '%s' "${VENDOR_REGISTRY_TOKEN}" | ssh deploy "mkdir -p ~/.config/containers/systemd && podman login --authfile ~/.config/containers/auth.json -u '${VENDOR_REGISTRY_USER}' --password-stdin '${CI_REGISTRY}'"

echo "==> copy the Quadlet file and let systemd generate the unit"
scp -q "${FILE}" "deploy:.config/containers/systemd/${NAME}.container"
ssh deploy "systemctl --user daemon-reload && systemctl --user restart '${NAME}.service'"

echo "==> wait for ${URL}"
curl -fsS -o /dev/null --retry 40 --retry-delay 3 --retry-all-errors "${URL}/health"
curl -fsS "${URL}/api/version" | tee /dev/stderr | grep -q "\"version\":\"${VERSION}\"" \
  || { echo; echo "ERROR: ${URL} is up but does not run version ${VERSION}" >&2; exit 1; }
echo
ssh deploy "systemctl --user --no-pager --lines=0 status '${NAME}.service' | head -4; podman ps --filter name='${NAME}' --format '{{.Names}} {{.Image}} {{.Status}}'"
