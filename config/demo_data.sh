#!/usr/bin/env bash
set -euo pipefail

# Idempotent demo seeder. Uses `docker compose exec -T` so commands are
# routed to compose services (not bare container names) and the same -T
# flag works in TTY and non-TTY contexts (CI, pipes, scripts). Each
# mutating step is preceded by a pre-flight probe so re-running
# `make demodata` against an already-provisioned stack logs "skipping"
# lines instead of failing (D-06).
#
# Compose-service ↔ container-name map (compose names used below):
#   elasticsearch → elasticsearch         (docker-compose.elk.yml)
#   kibana        → kibana                (docker-compose.elk.yml)
#   web           → ralph_web             (docker-compose.ralph.yml)
#   admin         → vmc_admin             (docker-compose.vmc.yml)
#
# DC builds the compose command with every demo compose file plus the
# top-level toolkit dev compose, so service resolution always succeeds
# regardless of which `make` target started the stack. Run this script
# from the toolkit root (Makefile's `demodata` target ensures that).
DC=(docker compose --env-file vmc-demo/.env
    -f vmc-demo/compose/docker-compose.postgresql.yml
    -f vmc-demo/compose/docker-compose.elk.yml
    -f vmc-demo/compose/docker-compose.vmc.yml
    -f compose/docker-compose.vmc-dev.yml
    -f vmc-demo/compose/docker-compose.ralph.yml
    -f vmc-demo/compose/docker-compose.hive.yml
    -f vmc-demo/compose/docker-compose.elastalert.yml)

# --- Step 1: ElastAlert ------------------------------------------------------
# The jertel/elastalert2 image entrypoint creates writeback indices on every
# boot (RESEARCH §1.8). The legacy `elastalert-create-index` call is removed
# to avoid a binary-path mismatch with elastalert2 (now under /usr/local/bin).
echo "ElastAlert: index init handled by image entrypoint"

# --- Step 2: TheHive (D-02 best-effort restore, idempotency in inner script) -
echo "HIVE: create database (superuser login: admin, password: admin)"
"${DC[@]}" exec -T elasticsearch chmod +x /test_data/load.sh
"${DC[@]}" exec -T elasticsearch /test_data/load.sh

# --- Step 3: Ralph migrations (already idempotent — invoke unconditionally) --
echo "Ralph: Make migrations"
"${DC[@]}" exec -T web ralphctl migrate

# --- Step 4: Ralph demodata + sitetree + generate_ips (probed) ---------------
ralph_has_data=$("${DC[@]}" exec -T web ralphctl shell -c \
    "from ralph.assets.models import DataCenter; print(DataCenter.objects.exists())" \
    2>/dev/null | tr -d '[:space:]')
if [ "${ralph_has_data}" = "True" ]; then
    echo "Ralph: demo data already present; skipping ralphctl demodata"
else
    echo "Ralph: Load demo data  (login: ralph, password: ralph)"
    "${DC[@]}" exec -T web ralphctl demodata
    "${DC[@]}" exec -T web ralphctl sitetree_resync_apps
    "${DC[@]}" exec -T web python3 /test_data/generate_ips.py
fi

# --- Step 5: VMC loaddata (probed via Tenant.objects.exists()) ---------------
vmc_has_tenants=$("${DC[@]}" exec -T admin python3 -m vmc shell -c \
    "from vmc.elasticsearch.models import Tenant; print(Tenant.objects.exists())" \
    2>/dev/null | tr -d '[:space:]')
if [ "${vmc_has_tenants}" = "True" ]; then
    echo "VMC: Tenant fixtures already loaded; skipping"
else
    echo "VMC: Load data (superuser login: admin, password: admin)"
    "${DC[@]}" exec -T admin python3 -m vmc loaddata /test_data/demo_data.json
fi

# --- Step 6: VMC create_index (already idempotent per RESEARCH §11) ----------
"${DC[@]}" exec -T admin python3 -m vmc create_index

# --- Step 7: Kibana dashboards (probed via /api/saved_objects/_find) ---------
kibana_dashboards=$(curl -s \
    -H 'kbn-xsrf: true' \
    'http://localhost:5601/api/saved_objects/_find?type=dashboard&per_page=1' \
    | jq -r '.total // 0' 2>/dev/null || echo 0)
if [ "${kibana_dashboards}" -gt 0 ] 2>/dev/null; then
    echo "Kibana: dashboards already imported (${kibana_dashboards}); skipping"
else
    echo "Kibana: Import Sample Dashboards and KPIs"
    "${DC[@]}" exec -T kibana chmod +x /test_data/load.sh
    "${DC[@]}" exec -T kibana /test_data/load.sh
fi

# --- Step 8: generate_vulns (probed via vuln index count) --------------------
vuln_count=$(curl -s 'http://localhost:9200/vmc.vulnerability.*/_count' \
    | jq -r '.count // 0' 2>/dev/null || echo 0)
if [ "${vuln_count}" -gt 0 ] 2>/dev/null; then
    echo "VMC: vulnerability data already generated (${vuln_count} docs); skipping"
else
    echo "VMC: Prepare demo data"
    "${DC[@]}" exec -T admin python3 -W ignore /test_data/generate_vulns.py
fi
