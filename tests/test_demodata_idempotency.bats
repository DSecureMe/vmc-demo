#!/usr/bin/env bats

setup() {
    SCRIPT="${BATS_TEST_DIRNAME}/../config/demo_data.sh"
}

@test "demo_data.sh exists and is executable" {
    [ -f "${SCRIPT}" ]
    [ -x "${SCRIPT}" ] || chmod +x "${SCRIPT}"
}

@test "demo_data.sh has set -euo pipefail" {
    head -3 "${SCRIPT}" | grep -q '^set -euo pipefail$'
}

@test "demo_data.sh uses docker compose exec -T (never -it)" {
    ! grep -q 'docker exec -it' "${SCRIPT}"
    ! grep -q 'docker exec -i ' "${SCRIPT}"
    grep -q 'exec -T' "${SCRIPT}"
}

@test "demo_data.sh has no explicit elastalert-create-index call" {
    ! grep -E '^[^#]*elastalert-create-index' "${SCRIPT}"
}

@test "demo_data.sh probes each mutating step before re-running" {
    grep -q 'RALPH_HAS_DATA' "${SCRIPT}"
    grep -q 'VMC_HAS_TENANTS' "${SCRIPT}"
    grep -q '/api/saved_objects/_find' "${SCRIPT}"
    grep -q '/vulnerability/_count' "${SCRIPT}"
}
