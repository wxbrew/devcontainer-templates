#!/bin/bash
TEMPLATE_ID="$1"

set -e

SRC_DIR="/tmp/${TEMPLATE_ID}"
ID_LABEL="test-container=${TEMPLATE_ID}"

devcontainer exec --id-label ${ID_LABEL} --workspace-folder "${SRC_DIR}" /bin/sh -c \
    "if [ -f test-project/test.sh ]; then
        chmod +x test-project/test.sh || sudo chmod +x test-project/test.sh
        test-project/test.sh
    else
        ls -la
    fi"

# Cleanup
docker rm -f $(docker ps -aq --filter "label=${ID_LABEL}") 2>/dev/null || true
rm -rf "${SRC_DIR}"
