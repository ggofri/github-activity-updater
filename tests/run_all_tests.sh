#!/bin/bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${YELLOW}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

main() {
    log_info "Starting GitHub Activity Updater Test Suite"
    echo
    
    local overall_exit_code=0
    
    log_info "Running unit tests..."
    if bash "$(dirname "${BASH_SOURCE[0]}")/test_unit.sh"; then
        log_success "Unit tests passed"
    else
        log_error "Unit tests failed"
        overall_exit_code=1
    fi
    echo
    
    log_info "Running integration tests..."
    if bash "$(dirname "${BASH_SOURCE[0]}")/test_integration.sh"; then
        log_success "Integration tests passed"
    else
        log_error "Integration tests failed"
        overall_exit_code=1
    fi
    echo
    
    if [[ $overall_exit_code -eq 0 ]]; then
        log_success "All test suites passed!"
    else
        log_error "Some test suites failed!"
    fi
    
    exit $overall_exit_code
}

main "$@"
