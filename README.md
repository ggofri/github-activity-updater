# GitHub README Activity Updater

A GitHub Action that automatically updates your README.md with recent GitHub activity. Everything in a _101 lines yaml_!

*Inspired by [jamesgeorge007/github-activity-readme](https://github.com/jamesgeorge007/github-activity-readme)*

## Features

- 🚀 Fetches recent GitHub events via API
- 📝 Updates README between comment markers
- 🎯 Supports multiple event types (Push, PR, Issues, Comments, Create)
- ⚡ Configurable number of events
- 🔧 Customizable README path

## Usage

Add the following comment markers to your README.md where you want the activity to appear:

```markdown
## Recent Activity
<!--START_SECTION:activity-->
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🍴 Forked [is-a-dev/register](https://github.com/is-a-dev/register) - Oct 06
<!--END_SECTION:activity-->
```

Create a workflow file (e.g., `.github/workflows/update-activity.yml`):

```yaml
name: Update GitHub Activity
on:
  schedule:
    - cron: "*/30 * * * *"  # Every 30 minutes
  workflow_dispatch:

jobs:
  update-activity:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Update GitHub Activity
        uses: ggofri/github-activity-updater@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          username: your-username
```

## Inputs

| Input | Description | Required | Default |
|-------|-------------|----------|---------|
| `github-token` | GitHub token for API access (optional, but recommended for higher rate limits) | No | - |
| `username` | GitHub username to fetch activity for | Yes | - |
| `max-events` | Maximum number of events to display | No | `5` |
| `readme-path` | Path to README file | No | `README.md` |

## Example Output

```markdown
## Recent Activity
<!--START_SECTION:activity-->
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🍴 Forked [is-a-dev/register](https://github.com/is-a-dev/register) - Oct 06
<!--END_SECTION:activity-->
```

## Supported Event Types

- **PushEvent** 🚀 - Code pushes
- **PullRequestEvent** 🔄 - PR creation/updates
- **IssuesEvent** 🐛 - Issue creation/updates
- **IssueCommentEvent** 💬 - Comments on issues/PRs
- **CreateEvent** ✨ - Repository/branch creation
- **ReleaseEvent** 🎉 - Version releases
- **PullRequestReviewEvent** 👀 - PR reviews
- **ForkEvent** 🍴 - Repository forks
- **WatchEvent** ⭐ - Repository stars

## Live Example

See the action in action with ggofri's recent activity:

<!--START_SECTION:activity-->
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🚀 Pushed commits to [ggofri/register](https://github.com/ggofri/register) - Oct 06
- 🍴 Forked [is-a-dev/register](https://github.com/is-a-dev/register) - Oct 06
<!--END_SECTION:activity-->

## License

MIT
