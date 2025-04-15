#!/bin/bash
set -e

CUSTOM_DIR="${CONDA_DIR}/lib/python${PYTHON_MINOR_VERSION}/site-packages/notebook/static/custom"

cat <<EOF >"${CUSTOM_DIR}/config.json"
{
  "ephemeral": $([ -n "$LIFETIME" ] && echo 1 || echo 0),
  "lifetime": "$LIFETIME"
}
EOF
