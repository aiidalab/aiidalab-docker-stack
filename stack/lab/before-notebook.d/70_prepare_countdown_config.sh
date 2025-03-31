#!/bin/bash
set -e

CUSTOM_DIR="${CONDA_DIR}/lib/python${PYTHON_MINOR_VERSION}/site-packages/notebook/static/custom"

if [ "$LIFETIME" ]; then
    EPHEMERAL=true

    # Convert LIFETIME from HH:MM:SS to seconds
    IFS=: read -r H M S <<<"$LIFETIME"
    LIFETIME_SEC=$((10#$H * 3600 + 10#$M * 60 + 10#$S))

    # Calculate expiry timestamp in UTC
    EXPIRY=$(date -u -d "+${LIFETIME_SEC} seconds" +"%Y-%m-%dT%H:%M:%SZ")
    export EXPIRY
else
    EPHEMERAL=false
fi

export EPHEMERAL
envsubst <"${CUSTOM_DIR}/config.json.template" >"$CUSTOM_DIR/config.json"
rm "${CUSTOM_DIR}/config.json.template"
