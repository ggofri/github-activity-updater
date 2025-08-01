#!/bin/bash
# shellcheck source=tests/test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"
# shellcheck source=src/github_activity.sh
source "$(dirname "${BASH_SOURCE[0]}")/../src/github_activity.sh"

test_extract_events() {
    local sample_response
    sample_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/sample_api_response.json")
    
    local result
    result=$(extract_events "$sample_response")
    
    local event_count
    event_count=$(echo "$result" | wc -l | tr -d ' ')
    assert_equals "4" "$event_count" "Should extract exactly 4 valid events"
    assert_contains "$result" "PushEvent" "Should contain PushEvent"
    assert_contains "$result" "IssuesEvent" "Should contain IssuesEvent" 
    assert_contains "$result" "PullRequestEvent" "Should contain PullRequestEvent"
    assert_contains "$result" "WatchEvent" "Should contain WatchEvent"
    if [[ "$result" == *"DeleteEvent"* ]]; then
        log_error "Should not contain DeleteEvent (filtered out)"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        log_success "Correctly filters out DeleteEvent"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_format_event() {
    local result
    result=$(format_event "2024-07-31T15:30:00Z" "PushEvent" "testuser/test-repo")
    assert_contains "$result" "🚀 Pushed commits" "PushEvent should have correct emoji and text"
    assert_contains "$result" "[testuser/test-repo](https://github.com/testuser/test-repo)" "Should have correct repo link"
  
    result=$(format_event "2024-07-30T14:20:00Z" "IssuesEvent" "testuser/another-repo")
    assert_contains "$result" "🐛 Created/updated issue" "IssuesEvent should have correct emoji and text"
    if [[ "$result" == *"Recent"* ]] || [[ "$result" =~ Jul\ [0-9]+ ]] || [[ "$result" =~ [A-Za-z]+\ [0-9]+ ]]; then
        log_success "Date formatting works correctly"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Date formatting failed: $result"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    result=$(format_event "2024-07-29T13:10:00Z" "UnknownEvent" "testuser/test-repo")
    assert_contains "$result" "❓ Unknown activity" "Unknown event types should show unknown activity"
}

test_check_api_error() {
    local error_response
    error_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/api_error_response.json")
    
    local success_response
    success_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/sample_api_response.json")
    if check_api_error "$error_response"; then
        log_success "Correctly detects API error response"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Failed to detect API error response"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
    if ! check_api_error "$success_response"; then
        log_success "Correctly identifies success response"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Incorrectly flagged success response as error"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_get_api_error_message() {
    local error_response
    error_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/api_error_response.json")
    
    local result
    result=$(get_api_error_message "$error_response")
    assert_contains "$result" "API rate limit exceeded" "Should extract error message correctly"
}

test_generate_activity_markdown() {
    local events_data="2024-07-31T15:30:00Z|PushEvent|testuser/test-repo
2024-07-30T14:20:00Z|IssuesEvent|testuser/another-repo
2024-07-29T13:10:00Z|PullRequestEvent|testuser/test-repo"
    local result
    result=$(generate_activity_markdown "$events_data")
    local line_count
    line_count=$(echo "$result" | wc -l | tr -d ' ')
    assert_equals "3" "$line_count" "Should generate 3 lines for 3 events"
    result=$(generate_activity_markdown "$events_data" "2")
    line_count=$(echo "$result" | wc -l | tr -d ' ')
    assert_equals "2" "$line_count" "Should limit to 2 events when max_events=2"
    assert_contains "$result" "🚀 Pushed commits" "Should contain formatted PushEvent"
    assert_contains "$result" "🐛 Created/updated issue" "Should contain formatted IssuesEvent"
}

test_update_readme() {
    local temp_readme
    temp_readme=$(mktemp)
    cp "$(dirname "${BASH_SOURCE[0]}")/fixtures/sample_readme.md" "$temp_readme"
    
    local activity_content="- 🚀 Test activity 1
- 🐛 Test activity 2"
    update_readme "$temp_readme" "$activity_content"
    
    local updated_content
    updated_content=$(cat "$temp_readme")
    assert_contains "$updated_content" "🚀 Test activity 1" "Should contain first activity"
    assert_contains "$updated_content" "🐛 Test activity 2" "Should contain second activity"
    
    assert_contains "$updated_content" "## Other Section" "Should preserve other sections"
    assert_contains "$updated_content" "Some other content here" "Should preserve other content"
    
    assert_contains "$updated_content" "<!--START_SECTION:activity-->" "Should preserve start marker"
    assert_contains "$updated_content" "<!--END_SECTION:activity-->" "Should preserve end marker"
    
    rm -f "$temp_readme"
}

run_unit_tests() {
    log_info "Running unit tests for core functions"
    
    test_extract_events
    test_format_event
    test_check_api_error
    test_get_api_error_message
    test_generate_activity_markdown
    test_update_readme
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_unit_tests
fi
