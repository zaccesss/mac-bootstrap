# Workflows

| Workflow | Runs on | What it does |
| --- | --- | --- |
| [`bootstrap.yml`](bootstrap.yml) | Push to `main`, every pull request | On a macOS runner with the stock bash 3.2: checks Bash syntax, runs ShellCheck and runs the bootstrap test suite |
| [`markdownlint.yml`](markdownlint.yml) | Push to `main`, every pull request | Lints every markdown file against [`.markdownlint.json`](../../.markdownlint.json) |

Dependency updates are configured separately in [`../dependabot.yml`](../dependabot.yml), covering the GitHub Actions used across the workflows above.
