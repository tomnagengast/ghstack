# ghstack

Visualize your PR dependency tree.

```
#258 feat: add export button
main
└── #243 refactor: config-driven handlers
    ├── #245 feat: CSV download
    │   └── #258 feat: add export button
    │       └── #277 fix: export encoding
    └── #247 feat: generate env.yaml
```

## What it does

ghstack is a **read-only** PR stack visualizer. It derives a dependency DAG from GitHub PR `baseRefName` chains and renders it as a tree in your terminal.

It works with any branching strategy — stacked PRs, feature branches, whatever. No workflow changes required. If your PRs have base branches pointing at other PRs, ghstack will find and display the relationships.

## Features

- Tree visualization of PR dependency DAGs (not just linear stacks)
- Spine filtering — shows your current branch's lineage by default, `--all` for everything
- Navigation — `--up`/`--down` to move between parent/child PR branches
- Filters — by state (`--open`, `--draft`, `--merged`, `--closed`), time (`--created`, `--updated`), author (`--author`)
- DAG-preserving filters — filtered results expand to include full ancestor + descendant chains for context
- 3-tier cache — hot (<60s, instant), warm (60s-10min, incremental), cold (>10min, full fetch)
- Clickable PR links (cmd+click in supported terminals)
- Review status styling (approved, changes requested, commented)
- Worktree-aware navigation — `--up`/`--down` detect worktrees and print paths for shell `cd`
- Auto-shows author when multiple authors are visible

## Requirements

- [uv](https://docs.astral.sh/uv/) (Python package manager)
- [gh](https://cli.github.com/) (GitHub CLI, authenticated)
- Python 3.13+ (uv will manage this)

## Install

```sh
git clone https://github.com/tnagengast/ghstack.git
cd ghstack
bash setup.sh
```

`setup.sh` checks prerequisites, symlinks `ghstack` to `~/.local/bin/`, and prints shell integration instructions.

## Usage

```
ghstack                    # current branch's lineage (ancestors + descendants)
ghstack --all              # full tree, all PRs
ghstack --refresh          # force full API re-fetch (bypass cache)
ghstack --count            # print visible PR count
```

### Filters

Any filter flag switches to full-graph mode. Filters AND together.

```
ghstack --open             # open, non-draft PRs
ghstack --draft            # draft PRs only
ghstack --created [N]      # created within N days (default: 2)
ghstack --updated [N]      # updated within N days (default: 2)
ghstack --merged [N]       # merged within N days (default: 2)
ghstack --closed [N]       # closed/merged within N days (default: 2)
ghstack --author <login>   # filter by GitHub username
```

Combine freely: `ghstack --merged 7 --count`, `ghstack --all --created 7`

### Navigation

```
ghstack --up               # switch to parent PR branch (toward main)
ghstack --down             # switch to child PR branch (toward leaves)
```

With multiple children, `--down` shows a picker. In worktree repos, prints the target worktree path (requires shell wrapper to `cd`). In plain repos, runs `git checkout` directly.

### State model

| Flag | Matches |
|---|---|
| `--open` | `OPEN` and not draft |
| `--draft` | `OPEN` and `isDraft` |
| `--merged` | `MERGED` |
| `--closed` | `CLOSED` or `MERGED` |

## Styling

| Style | Meaning |
|---|---|
| green | open |
| gray/dim | draft |
| magenta | merged |
| red | closed |
| bg:amber | current branch |
| bg:green, white text | approved |
| underline | has review comments |
| double underline | changes requested |

## Shell integration

The `ghstack.zsh` wrapper enables `--up`/`--down` to change your shell's working directory (needed for worktree navigation, since a subprocess can't `cd` the parent shell).

Add to your `.zshrc`:

```sh
source /path/to/ghstack/ghstack.zsh
```

Without this, `--up`/`--down` still works — it just prints the path instead of navigating to it (worktrees) or uses `git checkout` directly (plain repos).

## How it works

1. Reads `git remote get-url origin` to identify the GitHub repo
2. Fetches PRs via GitHub GraphQL API (`gh api graphql`)
3. Builds an adjacency map from `baseRefName` → child PRs
4. Renders the DAG as a `rich.Tree`

**Caching**: API responses are stored at `~/.cache/ghstack/{owner}-{repo}.json`. The 3-tier strategy:
- **Hot** (<60s): returns cached data instantly (~0.1s, only runs `git branch --show-current`)
- **Warm** (60s-10min): incremental fetch of PRs updated since last check
- **Cold** (>10min or `--refresh`): full pagination of all open PRs

Merged/closed PR filters trigger supplemental time-bounded searches since the cold cache only fetches open PRs.

## Comparison with other tools

ghstack is the **read-only, zero-adoption** option. Other tools create and manage stacked PRs. ghstack just shows you what's already there.

| | ghstack | [Graphite](https://graphite.dev) | [spr](https://github.com/ejoffe/spr) | [ghstack (Facebook)](https://github.com/ezyang/ghstack) | [gh-stack](https://github.com/timothyandrew/gh-stack) |
|---|---|---|---|---|---|
| Read-only | Yes | No (manages branches) | No (manages PRs) | No (manages branches) | Mostly (annotates PR descriptions) |
| Workflow-agnostic | Yes | No (requires `gt` workflow) | No (commit-per-PR model) | No (own branch scheme) | Partial (needs shared identifier) |
| Full DAG (not just linear) | Yes | Yes | No (linear only) | No (linear only) | No (linear only) |
| CLI visualization | Rich tree | `gt log` tree | Status emoji list | Minimal | List in PR description |
| Branch navigation | `--up`/`--down` | `gt up`/`gt down` | No | No | No |
| Filtering | State, time, author | Limited | No | No | No |
| Free/OSS | Yes | Freemium | Yes (MIT) | Yes (MIT) | Yes (MIT, archived) |
| Requires adoption | No | Yes | Yes | Yes | Partial |

## License

MIT
