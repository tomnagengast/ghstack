---
name: ghstack
description: "PR stack tree visualizer CLI. Use when working with ghstack — viewing PR dependency trees, filtering PRs by state (open, draft, merged, closed), checking PR counts, understanding PR stack relationships, or debugging ghstack behavior. Triggers on: 'ghstack', 'PR stack', 'PR tree', 'show my PRs', 'PR dependencies'."
---

# ghstack

PR stack tree visualizer at `ghstack`. Shows parent/child PR relationships derived from GitHub `baseRefName` chains.

## Usage

```
ghstack                    # current branch's lineage (ancestors + descendants)
ghstack --all              # full tree, all PRs
ghstack --refresh          # force full API re-fetch (bypass cache)
ghstack --count            # print PR count instead of tree
```

### Navigation flags

```
ghstack --up               # switch to parent PR branch (toward main)
ghstack --down             # switch to child PR branch (toward leaves)
```

Navigation uses unfiltered PRs and exits before filter/display logic. In worktree repos, prints the target worktree path to stdout (requires `ghstack.zsh` shell wrapper to `cd`). In plain repos, runs `git checkout` directly. Multiple children trigger an interactive picker (menu on stderr, selection on stdin).

### Filter flags

Any filter flag switches to full-graph mode. Filters AND together.

```
ghstack --open             # open, non-draft PRs
ghstack --draft            # draft PRs only
ghstack --created [N]      # created within N days (default: 2)
ghstack --updated [N]      # updated within N days (default: 2)
ghstack --merged [N]       # merged within N days (default: 2)
ghstack --closed [N]       # closed/merged within N days (default: 2)
ghstack --author <login>   # filter by PR author login (case-insensitive)
```

Combine freely: `ghstack --merged 7 --count`, `ghstack --all --created 7`

#### DAG-preserving filter behavior

Filters don't strip individual PRs — they expand matched PRs to full ancestor + descendant chains. This preserves tree context: if a filtered PR is deep in a stack, its entire path from root is shown, plus all descendants.

### State model

- **open** = `OPEN` and not draft
- **draft** = `OPEN` and `isDraft`
- **merged** = `MERGED`
- **closed** = `CLOSED` or `MERGED` (closed contains merged)

### Styling

| Style | Meaning |
|---|---|
| green | open |
| gray/dim | draft |
| magenta | merged |
| red | closed |
| bg:#f6c177 | current branch |
| bg:green/white | approved |
| underline | has review comments |
| double underline | changes requested |

PR numbers are clickable links (cmd+click). Author is shown automatically when multiple distinct authors are visible.

## Architecture

- **Script**: `ghstack` — PEP 723 inline script (`uv run --script`), depends on `rich`
- **Shell wrapper**: `ghstack.zsh` — intercepts `--up`/`--down` to `cd` into worktree paths
- **Cache**: `~/.cache/ghstack/{owner}-{repo}.json`, PRs keyed by number string
- **3-tier cache**: hot (<60s, instant) / warm (60s-10min, incremental search) / cold (>10min, full fetch)
- **Data source**: GitHub GraphQL API via `gh api graphql`
- Cold fetch uses `PULLS_QUERY` (only `states: [OPEN]`); `--merged`/`--closed` do supplemental `search_prs()` calls with time-bounded qualifiers
- Spine filter: without `--all` or filter flags, only shows current branch's ancestor chain + their descendants

## Key functions

- `resolve_repo()` — git remote → `(repo_id, owner, repo_name)`
- `fetch_cold()` / `fetch_incremental()` / `fetch_all()` — data fetching with cache tiers
- `search_prs(owner, repo_name, qualifiers)` — reusable GitHub search pagination
- `collect_spine()` — walk baseRefName chain from current branch to root, return set of branch names
- `collect_visible_prs()` — collect PRs that would be rendered (respects spine/subtree visibility logic)
- `build_tree_recursive()` — tree rendering with spine/subtree visibility
- `find_worktree_path(branch)` — parse `git worktree list --porcelain` to find worktree dir for a branch
- `pick_branch(children)` — interactive picker when `--down` has multiple children
- `build_style()` — PR state → Rich Style
- Filter predicates built in `main()` as lambda list, AND'd together

## Modifying ghstack

When adding new filter flags: add argparse arg, add predicate lambda, and if the filter needs non-OPEN PRs, add a supplemental `search_prs()` call before the filter section.

When adding navigation commands: add to the `--up`/`--down` mutually exclusive group, handle before filter/display logic (navigation exits early).
