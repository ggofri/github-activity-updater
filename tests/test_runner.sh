#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

log_info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[PASS]${NC} $*"; }
log_error() { echo -e "${RED}[FAIL]${NC} $*"; }

assert_equals() {
    local expected="$1"
    local actual="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$expected" == "$actual" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Assert equals: $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "Assert equals failed: $message"
        log_error "  Expected: '$expected'"
        log_error "  Actual:   '$actual'"
        return 1
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local message="${3:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ "$haystack" == *"$needle"* ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Assert contains: $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "Assert contains failed: $message"
        log_error "  Haystack: '$haystack'"
        log_error "  Needle:   '$needle'"
        return 1
    fi
}

assert_file_exists() {
    local file="$1"
    local message="${2:-}"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [[ -f "$file" ]]; then
        TESTS_PASSED=$((TESTS_PASSED + 1))
        log_success "Assert file exists: $message"
        return 0
    else
        TESTS_FAILED=$((TESTS_FAILED + 1))
        log_error "Assert file exists failed: $message"
        log_error "  File: '$file'"
        return 1
    fi
}

print_summary() {
    echo
    echo "=================================="
    echo "Test Summary"
    echo "=================================="
    echo "Tests run:    $TESTS_RUN"
    echo "Tests passed: $TESTS_PASSED"
    echo "Tests failed: $TESTS_FAILED"
    echo
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        log_success "All tests passed!"
        exit 0
    else
        log_error "Some tests failed!"
        exit 1
    fi
}

main() {
    log_info "Starting GitHub Activity Updater Test Suite"
    echo
    
    for test_file in tests/test_*.sh; do
        if [[ -f "$test_file" && "$test_file" != "tests/test_runner.sh" ]]; then
            log_info "Running $(basename "$test_file")"
            # shellcheck source=/dev/null
            source "$test_file"
            echo
        fi
    done
    
    print_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
