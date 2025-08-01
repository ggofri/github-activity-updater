#!/bin/bash
# shellcheck source=tests/test_helpers.sh
source "$(dirname "${BASH_SOURCE[0]}")/test_helpers.sh"

mock_curl() {
    local url="$*"
    
    local page=1
    if [[ "$url" == *"page="* ]]; then
        page=$(echo "$url" | grep -o 'page=[0-9]*' | cut -d'=' -f2)
    fi
    
    case "$page" in
        1) cat "tests/fixtures/sample_api_response.json" ;;
        *) echo "[]" ;;  # Empty response for other pages
    esac
}

test_full_workflow_success() {
    log_info "Testing full workflow with successful API response"
    
    local temp_readme
    temp_readme=$(mktemp)
    cp "$(dirname "${BASH_SOURCE[0]}")/fixtures/sample_readme.md" "$temp_readme"
    
    local temp_events
    temp_events=$(mktemp)
    local activity_content
    activity_content=$(mktemp)
    
    local username="testuser"
    local token=""
    local max_events=5
    local readme="$temp_readme"
    local debug="false"
    
    : "$username" "$token" "$debug"
    
    local api_response
    api_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/sample_api_response.json")
    
    echo "$api_response" | jq -r '.[] | select(.type | test("^(Push|Issues|PullRequest|IssueComment|Create|Release|PullRequestReview|Fork|Watch)Event$")) | "\(.created_at)|\(.type)|\(.repo.name)"' > "$temp_events"
    
    head -n "$max_events" "$temp_events" | while IFS='|' read -r date type repo; do
        formatted_date=$(date -d "$date" "+%b %d" 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date" "+%b %d" 2>/dev/null || echo "Recent")
        case "$type" in
            PushEvent) echo "- 🚀 Pushed commits to [$repo](https://github.com/$repo) - $formatted_date" ;;
            PullRequestEvent) echo "- 🔄 Opened/updated PR in [$repo](https://github.com/$repo) - $formatted_date" ;;
            IssuesEvent) echo "- 🐛 Created/updated issue in [$repo](https://github.com/$repo) - $formatted_date" ;;
            IssueCommentEvent) echo "- 💬 Commented on issue in [$repo](https://github.com/$repo) - $formatted_date" ;;
            CreateEvent) echo "- ✨ Created repository or branch [$repo](https://github.com/$repo) - $formatted_date" ;;
            ReleaseEvent) echo "- 🎉 Released version in [$repo](https://github.com/$repo) - $formatted_date" ;;
            PullRequestReviewEvent) echo "- 👀 Reviewed PR in [$repo](https://github.com/$repo) - $formatted_date" ;;
            ForkEvent) echo "- 🍴 Forked [$repo](https://github.com/$repo) - $formatted_date" ;;
            WatchEvent) echo "- ⭐ Starred [$repo](https://github.com/$repo) - $formatted_date" ;;
        esac
    done > "$activity_content"
    
    awk '
    /<!--START_SECTION:activity-->/ { print; system("cat '"$activity_content"'"); skip=1; next }
    /<!--END_SECTION:activity-->/ { skip=0 }
    skip==0 { print }
    ' "$readme" > "$readme.tmp" && mv "$readme.tmp" "$readme"
    
    local updated_content
    updated_content=$(cat "$readme")
    
    assert_contains "$updated_content" "🚀 Pushed commits to [testuser/test-repo]" "Should contain PushEvent"
    assert_contains "$updated_content" "🐛 Created/updated issue in [testuser/another-repo]" "Should contain IssuesEvent"
    assert_contains "$updated_content" "🔄 Opened/updated PR in [testuser/test-repo]" "Should contain PullRequestEvent"
    assert_contains "$updated_content" "⭐ Starred [opensource/popular-project]" "Should contain WatchEvent"
    
    assert_contains "$updated_content" "## Other Section" "Should preserve other sections"
    assert_contains "$updated_content" "More content that should remain unchanged" "Should preserve all original content"
    
    rm -f "$temp_readme" "$temp_events" "$activity_content" "$readme.tmp"
}

test_api_error_handling() {
    log_info "Testing API error handling"
    
    local error_response
    error_response=$(cat "$(dirname "${BASH_SOURCE[0]}")/fixtures/api_error_response.json")
    
    if echo "$error_response" | jq -e '.message' >/dev/null 2>&1; then
        local error_msg
        error_msg=$(echo "$error_response" | jq -r '.message')
        assert_contains "$error_msg" "API rate limit exceeded" "Should detect rate limit error"
        log_success "API error handling works correctly"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        log_error "Failed to detect API error"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

test_empty_api_response() {
    log_info "Testing empty API response handling"
    
    local empty_response="[]"
    local events_count
    events_count=$(echo "$empty_response" | jq '. | length')
    
    assert_equals "0" "$events_count" "Empty response should have 0 events"
    
    local result
    result=$(echo "$empty_response" | jq -r '.[] | select(.type | test("^(Push|Issues|PullRequest|IssueComment|Create|Release|PullRequestReview|Fork|Watch)Event$")) | "\(.created_at)|\(.type)|\(.repo.name)"' || echo "")
    
    assert_equals "" "$result" "Empty response should produce no events"
}

test_max_events_limit() {
    log_info "Testing max events limit functionality"
    
    local temp_events
    temp_events=$(mktemp)
    
    echo "2024-07-31T15:30:00Z|PushEvent|repo1
2024-07-30T14:20:00Z|IssuesEvent|repo2  
2024-07-29T13:10:00Z|PullRequestEvent|repo3
2024-07-28T12:00:00Z|WatchEvent|repo4
2024-07-27T11:00:00Z|CreateEvent|repo5
2024-07-26T10:00:00Z|ReleaseEvent|repo6
2024-07-25T09:00:00Z|ForkEvent|repo7" > "$temp_events"
    
    local result
    result=$(head -n 3 "$temp_events")
    local line_count
    line_count=$(echo "$result" | wc -l | tr -d ' ')
    
    assert_equals "3" "$line_count" "Should limit to exactly 3 events"
    
    result=$(head -n 5 "$temp_events")
    line_count=$(echo "$result" | wc -l | tr -d ' ')
    
    assert_equals "5" "$line_count" "Should limit to exactly 5 events"
    
    rm -f "$temp_events"
}

test_readme_markers_preservation() {
    log_info "Testing README section markers preservation"
    
    local temp_readme
    temp_readme=$(mktemp)
    
    cat > "$temp_readme" << 'EOF'
# Test README

## First Activity Section
<!--START_SECTION:activity-->
Old content here
<!--END_SECTION:activity-->

## Some Other Content

This should not be touched.

## Another Activity Section
<!--START_SECTION:activity-->
More old content
<!--END_SECTION:activity-->

## Final Section

This should also be preserved.
EOF
    
    local activity_content="- 🚀 New activity"
    
    awk '
    /<!--START_SECTION:activity-->/ { print; system("echo \"'"$activity_content"'\""); skip=1; next }
    /<!--END_SECTION:activity-->/ { skip=0 }
    skip==0 { print }
    ' "$temp_readme" > "$temp_readme.tmp" && mv "$temp_readme.tmp" "$temp_readme"
    
    local updated_content
    updated_content=$(cat "$temp_readme")
    
    local activity_count
    activity_count=$(echo "$updated_content" | grep -c "🚀 New activity" || echo 0)
    assert_equals "2" "$activity_count" "Should update both activity sections"
    
    assert_contains "$updated_content" "This should not be touched" "Should preserve non-activity content"
    assert_contains "$updated_content" "## Final Section" "Should preserve all sections"
    assert_contains "$updated_content" "This should also be preserved" "Should preserve all content outside activity sections"
    assert_contains "$updated_content" "# Test README" "Should preserve README title"
    assert_contains "$updated_content" "## Some Other Content" "Should preserve other section headers"
    
    rm -f "$temp_readme"
}

run_integration_tests() {
    log_info "Running integration tests for full workflow"
    
    test_full_workflow_success
    test_api_error_handling
    test_empty_api_response
    test_max_events_limit  
    test_readme_markers_preservation
    
    print_test_summary
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_tests
fi
