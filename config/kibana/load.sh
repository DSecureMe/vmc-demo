#!/usr/bin/env bash
set -euo pipefail

# KBN_VERSION is injected from docker-compose.elk.yml (via vmc-demo/.env ELK_VERSION).
# Fail loudly if unset so a missing env passthrough surfaces immediately
# instead of hitting Kibana with a stale hard-coded value (D-09).
: "${KBN_VERSION:?KBN_VERSION must be set (passed from docker compose env via vmc-demo/.env)}"

# Kibana 7.17 saved-objects import API.
# -f: fail on HTTP >= 400 so set -e aborts if Kibana rejects the import.
# -s: silent progress meter.
# -S: still show errors on stderr.
# Headers: kbn-xsrf (anti-CSRF, demo runs with xpack.security disabled) and
# kbn-version (must match the running Kibana major.minor — RESEARCH §2).
curl -fsS \
    -X POST "http://localhost:5601/api/saved_objects/_import?overwrite=true" \
    -H "kbn-xsrf: true" \
    -H "kbn-version: ${KBN_VERSION}" \
    -F file=@/test_data/export.ndjson
