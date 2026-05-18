#!/usr/bin/env bash
set -euo pipefail

: "${KBN_VERSION:?KBN_VERSION must be set (docker-compose.elk.yml env)}"

curl -fsS -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -H "kbn-version: ${KBN_VERSION}" \
    -F file=@/test_data/export.ndjson
