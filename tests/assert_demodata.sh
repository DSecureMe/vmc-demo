#!/usr/bin/env bash
set -euo pipefail

ES_URL="${ES_URL:-http://localhost:9200}"
KIBANA_URL="${KIBANA_URL:-http://localhost:5601}"
VMC_URL="${VMC_URL:-http://localhost:8080}"
KBN_VERSION="${KBN_VERSION:-7.17.13}"

assert_count_gt() {
    local index=$1 minimum=$2
    local count
    count=$(curl -sf "${ES_URL}/${index}/_count" | jq -r '.count // 0')
    if [ "${count}" -le "${minimum}" ]; then
        echo "FAIL: ${index} has ${count} docs, expected > ${minimum}" >&2
        return 1
    fi
    echo "OK: ${index} has ${count} docs"
}

assert_count_gt cve 0
assert_count_gt cwe 0
assert_count_gt asset 0
assert_count_gt vulnerability 0

dashboards=$(curl -sf -H 'kbn-xsrf: true' -H "kbn-version: ${KBN_VERSION}" \
    "${KIBANA_URL}/api/saved_objects/_find?type=dashboard&per_page=1" \
    | jq -r '.total // 0')
if [ "${dashboards}" -lt 1 ]; then
    echo "FAIL: Kibana has no dashboards" >&2
    exit 1
fi
echo "OK: Kibana has ${dashboards} dashboard(s)"

code=$(curl -s -o /dev/null -w '%{http_code}' "${VMC_URL}/admin/login/")
if [ "${code}" != "200" ]; then
    echo "FAIL: ${VMC_URL}/admin/login/ returned HTTP ${code}" >&2
    exit 1
fi
echo "OK: ${VMC_URL}/admin/login/ returned 200"
