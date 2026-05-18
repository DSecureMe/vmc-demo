#!/usr/bin/env bash
set -euo pipefail

ES_URL="http://localhost:9200"

if curl -fsS "${ES_URL}/hive_16/_count" >/dev/null 2>&1; then
    echo "TheHive: hive_16 index already exists; skipping restore"
    exit 0
fi

if ! curl -fsS -XPUT "${ES_URL}/_snapshot/the_hive_backup" \
        -H 'Content-Type: application/json' \
        -d '{"type":"fs","settings":{"location":"/test_data","compress":true}}' \
        >/dev/null; then
    echo "WARNING: snapshot repo registration failed; falling back to empty TheHive DB (admin/admin)" >&2
    exit 0
fi

http_code=$(curl -s -o /tmp/restore_resp.json -w '%{http_code}' \
    -XPOST "${ES_URL}/_snapshot/the_hive_backup/snapshot_2/_restore" \
    -H 'Content-Type: application/json' \
    -d '{"indices":"hive_16"}')

case "${http_code}" in
    200|202)
        echo "TheHive: snapshot restored successfully"
        ;;
    *)
        if grep -qE 'resource_already_exists_exception|already exists' /tmp/restore_resp.json 2>/dev/null; then
            echo "TheHive: hive_16 already restored; skipping"
        else
            echo "WARNING: TheHive snapshot restore failed (HTTP ${http_code}); falling back to empty DB (admin/admin)" >&2
            cat /tmp/restore_resp.json >&2 || true
            echo >&2
        fi
        ;;
esac
