#!/usr/bin/env bash
set -euo pipefail

DEMO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLKIT_ROOT="$(cd "${DEMO_ROOT}/.." && pwd)"

DC=(docker compose --env-file "${DEMO_ROOT}/.env"
    -f "${DEMO_ROOT}/compose/docker-compose.postgresql.yml"
    -f "${DEMO_ROOT}/compose/docker-compose.elk.yml"
    -f "${DEMO_ROOT}/compose/docker-compose.vmc.yml"
    -f "${DEMO_ROOT}/compose/docker-compose.ralph.yml"
    -f "${DEMO_ROOT}/compose/docker-compose.hive.yml"
    -f "${DEMO_ROOT}/compose/docker-compose.elastalert.yml")

if [ -f "${TOOLKIT_ROOT}/compose/docker-compose.vmc-dev.yml" ]; then
    DC+=(-f "${TOOLKIT_ROOT}/compose/docker-compose.vmc-dev.yml")
fi

echo "ElastAlert: index init handled by image entrypoint"

echo "HIVE: create database (superuser login: admin, password: admin)"
"${DC[@]}" exec -T elasticsearch chmod +x /test_data/load.sh
"${DC[@]}" exec -T elasticsearch /test_data/load.sh

echo "Ralph: Make migrations"
"${DC[@]}" exec -T web ralphctl migrate

ralph_has_data=$(echo "from ralph.data_center.models import DataCenter; print('RALPH_HAS_DATA:' + str(DataCenter.objects.exists()))" \
    | "${DC[@]}" exec -T web ralphctl shell --plain 2>/dev/null \
    | grep -oE 'RALPH_HAS_DATA:(True|False)' | head -1 | cut -d: -f2)
if [ "${ralph_has_data}" = "True" ]; then
    echo "Ralph: demo data already present; skipping"
else
    echo "Ralph: Load demo data  (login: ralph, password: ralph)"
    "${DC[@]}" exec -T web ralphctl demodata
    "${DC[@]}" exec -T web ralphctl sitetree_resync_apps
    "${DC[@]}" exec -T web python3 /test_data/generate_ips.py
fi

vmc_has_tenants=$("${DC[@]}" exec -T admin python3 -m vmc shell -c \
    "from vmc.elasticsearch.models import Tenant; print('VMC_HAS_TENANTS:' + str(Tenant.objects.exists()))" \
    2>/dev/null | grep -oE 'VMC_HAS_TENANTS:(True|False)' | head -1 | cut -d: -f2)
if [ "${vmc_has_tenants}" = "True" ]; then
    echo "VMC: Tenant fixtures already loaded; skipping"
else
    echo "VMC: Load data (superuser login: admin, password: admin)"
    "${DC[@]}" exec -T admin python3 -m vmc loaddata /test_data/demo_data.json
fi

"${DC[@]}" exec -T admin python3 -m vmc create_index

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

vuln_count=$(curl -s 'http://localhost:9200/vulnerability/_count' \
    | jq -r '.count // 0' 2>/dev/null || echo 0)
if [ "${vuln_count}" -gt 0 ] 2>/dev/null; then
    echo "VMC: vulnerability data already generated (${vuln_count} docs); skipping"
else
    echo "VMC: Prepare demo data"
    "${DC[@]}" exec -T admin python3 -W ignore /test_data/generate_vulns.py
fi
