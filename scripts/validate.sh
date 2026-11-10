#!/usr/bin/env bash
# Check the Quadlet files with Podman's own generator (no server needed): a typo in a key fails here, in the merge
# request, instead of on the server.   scripts/validate.sh
set -euo pipefail

for dir in quadlet/*/; do
  echo "==> ${dir}"
  QUADLET_UNIT_DIRS="$(pwd)/${dir}" /usr/libexec/podman/quadlet -dryrun -user
done
