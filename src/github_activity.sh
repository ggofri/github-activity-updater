#!/bin/bash

set -euo pipefail
extract_events() {
    local api_response="$1"
    echo "$api_response" | jq -r '.[] | select(.type | test("^(Push|Issues|PullRequest|IssueComment|Create|Release|PullRequestReview|Fork|Watch)Event$")) | "\(.created_at)|\(.type)|\(.repo.name)"'
}
format_event() {
    local date="$1"
    local type="$2" 
    local repo="$3"
    
    local formatted_date
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
        *) echo "- ❓ Unknown activity in [$repo](https://github.com/$repo) - $formatted_date" ;;
    esac
}
check_api_error() {
    local api_response="$1"
    if echo "$api_response" | jq -e '.message' >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}
get_api_error_message() {
    local api_response="$1"
    echo "$api_response" | jq -r '.message'
}
update_readme() {
    local readme_file="$1"
    local activity_content="$2"
    local temp_file="${readme_file}.tmp"
    local activity_temp
    activity_temp=$(mktemp)
    echo "$activity_content" > "$activity_temp"
    awk '
    /<!--START_SECTION:activity-->/ { print; system("cat '"$activity_temp"'"); skip=1; next }
    /<!--END_SECTION:activity-->/ { skip=0 }
    skip==0 { print }
    ' "$readme_file" > "$temp_file" && mv "$temp_file" "$readme_file"
    rm -f "$activity_temp"
}
generate_activity_markdown() {
    local events_data="$1"
    local max_events="${2:-5}"
    echo "$events_data" | head -n "$max_events" | while IFS='|' read -r date type repo; do
        format_event "$date" "$type" "$repo"
    done
}
