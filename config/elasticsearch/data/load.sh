#!/usr/bin/env bash
set -euo pipefail

# TheHive 3.5 demo data restore — best-effort per D-02.
# Strategy:
#   1. Cheap pre-flight existence probe (idempotency, RESEARCH §"Pattern 2").
#   2. Register snapshot repo; on failure log a visible WARNING and exit 0
#      so make demodata continues with an empty TheHive DB (admin/admin).
#   3. Attempt restore; branch on HTTP code to distinguish success, an
#      idempotent already-exists response, and "fall back to empty DB".
# All success and fallback branches exit 0 — degraded state is observable
# via the WARNING line on stderr, not a non-zero exit.

ES_URL="http://localhost:9200"

# 1. Idempotency probe — if hive_16 is already populated, no work to do.
if curl -fsS "${ES_URL}/hive_16/_count" >/dev/null 2>&1; then
    echo "TheHive: hive_16 index already exists; skipping restore"
    exit 0
fi

# 2. Register the snapshot repository.
if ! curl -fsS -XPUT "${ES_URL}/_snapshot/the_hive_backup" \
        -H 'Content-Type: application/json' \
        -d '{"type":"fs","settings":{"location":"/test_data","compress":true}}' \
        >/dev/null; then
    echo "WARNING: snapshot repo registration failed; falling back to empty TheHive DB (admin/admin)" >&2
    exit 0
fi

# 3. Attempt the restore. Capture the HTTP status without aborting on a
# non-2xx response — we branch on it below.
http_code=$(curl -s -o /tmp/restore_resp.json -w '%{http_code}' \
    -XPOST "${ES_URL}/_snapshot/the_hive_backup/snapshot_2/_restore" \
    -H 'Content-Type: application/json' \
    -d '{"indices":"hive_16"}')

case "${http_code}" in
    200|202)
        echo "TheHive: snapshot restored successfully"
        exit 0
        ;;
    *)
        if grep -qE 'resource_already_exists_exception|already exists' /tmp/restore_resp.json 2>/dev/null; then
            echo "TheHive: hive_16 already restored; skipping (idempotent)"
            exit 0
        fi
        echo "WARNING: TheHive snapshot restore failed (HTTP ${http_code}); falling back to empty DB (admin/admin)" >&2
        echo "  ES response body:" >&2
        cat /tmp/restore_resp.json >&2 || true
        echo >&2
        exit 0
        ;;
esac
