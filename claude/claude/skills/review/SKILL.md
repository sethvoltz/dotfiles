---
name: review
description: Review a diff along two deliberately separate axes — Standards (does it conform to documented repo standards?) and Spec (does it faithfully implement the originating intent?). Spawns both axes as parallel sub-agents to keep contexts clean, then reports them side-by-side without merging. Use when the user wants to review a branch, a PR, or work-in-progress changes, or asks to "review since X". Handles three diff sources: the local branch since trunk (committed + working tree), a fixed point the user names (committed only), or an open PR on the current branch.
---

# Review

A change can pass one axis and fail the other:

- Code that follows every standard but implements the wrong thing → **Standards pass, Spec fail.**
- Code that does exactly what the issue asked but breaks the project's conventions → **Spec pass, Standards fail.**

Reporting them separately stops one axis from masking the other. Never merge or re-rank the two reports.

## 1. Pick the diff source

Three modes. Pick one and capture both a **diff command** and a **commit list** (the commit list may be empty if there are no commits since the base).

### Branch (default for local work)
Reviews everything on the current branch since it diverged from trunk, **including uncommitted and unstaged changes** to tracked files, plus any new untracked files. The right mode for "review what I've been working on" or "review what I'd push."

- **Detect trunk:** try `origin/main`, fall back to `origin/master`. If neither exists, ask.
- Diff (tracked changes): `git diff $(git merge-base <trunk> HEAD)` (single ref — picks up committed work *and* working-tree edits to tracked files)
- Commits: `git log $(git merge-base <trunk> HEAD)..HEAD --oneline`
- Untracked files: `git ls-files --others --exclude-standard`. **Untracked files do not appear in `git diff`** — this skill does not mutate the index to make them appear. Instead, the returned paths get passed to the sub-agents as "new files; read them directly."

### Fixed point
Use when the user explicitly names a base — commit SHA, branch, tag, `HEAD~5`, etc. **Committed work only**, no working tree.

- Diff: `git diff <fixed-point>...HEAD` (three-dot, vs. merge-base)
- Commits: `git log <fixed-point>..HEAD --oneline`

### Open PR
Use when reviewing a PR (yours or someone else's). Detect with `gh pr view --json number,baseRefName,headRefName,body,closingIssuesReferences`. **Committed work only.**

- Diff: `git diff origin/<baseRefName>...HEAD`
- Commits: `git log origin/<baseRefName>..HEAD --oneline`
- This skill does not fetch. If `origin/<baseRefName>` is behind the real remote, the diff will be wrong (it'll include changes that have already merged). If the user wants fresh state they should `git fetch` themselves before invoking.

### Mode selection
- User named a fixed point explicitly → **Fixed point**.
- Else `gh pr view --json number` returns a PR → confirm *"Reviewing PR #N against `<base>`?"*, then **PR**.
- Else → **Branch** (with the detected trunk; ask if trunk is ambiguous).

## 2. Identify spec sources

Look for the originating intent in this order. **Take the first source that yields something concrete and stop** — don't grind through all five.

1. **PR body + linked GitHub issues** (PR mode) — read the PR body. `gh pr view --json closingIssuesReferences` returns a flat array of `{number, title, repository: {nameWithOwner}, ...}` — iterate it directly (no `.nodes` wrapper). For each entry, fetch with `gh issue view <number> --repo <repository.nameWithOwner> --json title,body,comments`. The repo qualifier matters because closing issues can live in a different repo from the PR. Note: this field **only covers GitHub-issue closes** — Linear/Jira/etc. tickets referenced in the PR body won't appear here; step 2 finds those.
2. **Issue refs in commit messages and PR body** — scan for refs in any of these shapes:
   - `#N` or `owner/repo#N` (GitHub)
   - `UPPER-N` like `ENG-456`, `TC-123`, `PROJ-789` (Linear, Jira, Shortcut, Asana — any tracker that uses `PREFIX-DIGITS` keys)
   - `!N` (GitLab MR)

   Fetch via whichever tool resolves the reference in this session: `gh issue view` for GitHub, the matching MCP server for external trackers (e.g. `mcp__linear__get_issue` for Linear — check what MCP tools are loaded), or the project's documented workflow if one exists (e.g. `docs/agents/issue-tracker.md`). If a ref pattern matches but no tool is available to fetch it, note the ref in the report and continue.
3. **A path the user passed** as an argument.
4. **A PRD/spec file** under `docs/`, `specs/`, `.scratch/`, or similar, matching the branch name or feature.
5. If nothing turns up, **ask**. If the user confirms there is no spec, the Spec sub-agent skips and the final report notes "no spec available". Do not invent a spec from the diff.

## 3. Identify standards sources

Walk the repo once. Collect paths only — let the sub-agent read them.

- Repo-root agent/contributor docs: `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING.md`, `CONTEXT.md`, `CONTEXT-MAP.md`
- Style/standards docs at root or under `docs/`: `STYLE.md`, `STANDARDS.md`, `STYLEGUIDE.md`
- **Nested** agent/standards docs in monorepos: `find . -type f \( -name CLAUDE.md -o -name AGENTS.md -o -name CONTEXT.md \) -not -path '*/node_modules/*' -not -path '*/.git/*'`
- Architectural decisions: every file under `docs/adr/` or `docs/decisions/`
- Machine-enforced standards (`.editorconfig`, `eslint.config.*`, `biome.json`, `prettier.config.*`, `tsconfig.json`, `ruff.toml`, `pyproject.toml`, etc.) — note their presence so the sub-agent can **skip what tooling already enforces**, but don't ask it to re-derive those rules.

## 4. Spawn both sub-agents in parallel

Send a single message with two `Agent` tool calls. Use `general-purpose` for both. The parallelism is for **context isolation**, not speed — each axis must read the diff with no awareness of the other's findings.

**Standards sub-agent prompt** — include:

- The full diff command and commit list.
- The list of untracked-file paths (Branch mode only, if any) with the instruction: "these are new files in this change; read them directly — they are not in the diff."
- The list of standards-source file paths from step 3.
- The brief: *"Read the standards docs. Then read the diff and any untracked-file paths. Report — per file/hunk where relevant — every place the change violates a documented standard. Cite the standard (file + the rule, quoted briefly). Distinguish hard violations from judgement calls. Skip anything tooling already enforces. Under 400 words."*

**Spec sub-agent prompt** — include:

- The diff command and commit list.
- The list of untracked-file paths (Branch mode only, if any) with the same "read directly, not in the diff" instruction.
- The fetched contents (or paths) of the spec sources from step 2. In PR mode, include the PR body verbatim and each linked issue body verbatim.
- The brief: *"Read the spec. Then read the diff and any untracked-file paths. Report: (a) requirements the spec asked for that are missing or partial; (b) behaviour in the change that wasn't asked for (scope creep); (c) requirements that look implemented but where the implementation looks wrong. Quote the spec line for each finding. Under 400 words."*

If no spec was found, skip the Spec sub-agent — do not run it with an empty input.

## 5. Aggregate

Present the two reports under `## Standards` and `## Spec` headings, verbatim or lightly cleaned. Do **not** merge findings, do **not** rerank, do **not** add your own synthesis on top.

End with a one-line footer: total findings per axis, and the single worst issue flagged (if any).

If the Spec sub-agent was skipped, render `## Spec` as a single line: *"No spec available — skipped."*

## Notes

- **PR body ≠ spec.** The PR body is usually a summary written *after* implementation. Always follow `closingIssuesReferences` if present — the issue is the spec, the PR body is the cover letter.
- **Diff form by mode.** Branch mode uses a single ref (`git diff <merge-base>`) — that's the form that includes the working tree. Fixed-point and PR modes use three-dot (`A...B`) — that diffs against the merge-base, which is what you want when the base branch has moved on. Two-dot (`A..B`) is for `git log`, not `git diff`.
- **Large diffs.** If the diff is enormous (e.g. >2000 lines), tell the user before dispatching sub-agents and ask whether to scope down (specific paths, specific commits) rather than blindly fanning out an unbounded review.
