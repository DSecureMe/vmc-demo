#!/usr/bin/env bats

setup() {
    SCRIPT="${BATS_TEST_DIRNAME}/../config/kibana/load.sh"
    ELK_COMPOSE="${BATS_TEST_DIRNAME}/../compose/docker-compose.elk.yml"
    ENV_FILE="${BATS_TEST_DIRNAME}/../.env"
}

@test "kibana/load.sh reads kbn-version from \$KBN_VERSION env" {
    grep -Fq 'kbn-version: ${KBN_VERSION}' "${SCRIPT}"
}

@test "kibana/load.sh fails loudly if \$KBN_VERSION is unset" {
    grep -q 'KBN_VERSION:?' "${SCRIPT}"
}

@test "kibana/load.sh has no hard-coded 7.5.0 header" {
    ! grep -q '7\.5\.0' "${SCRIPT}"
}

@test ".env exports KBN_VERSION derived from ELK_VERSION" {
    grep -Fq 'KBN_VERSION=${ELK_VERSION}' "${ENV_FILE}"
}

@test "docker-compose.elk.yml passes KBN_VERSION into kibana service env" {
    grep -A 20 '^  kibana:' "${ELK_COMPOSE}" | grep -Fq 'KBN_VERSION=${ELK_VERSION}'
}
