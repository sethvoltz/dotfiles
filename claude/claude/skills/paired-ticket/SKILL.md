---
name: paired-ticket
description: Produce a /loop-ready Linear ticket via a two-stage research → adversarial-review pipeline. Stage 1 dispatches a research subagent that designs the change and files a ticket (no implementation). Stage 2 dispatches a cold-start review subagent that truth-validates every claim, re-runs inventories, probes library behavior at runtime, tightens acceptance criteria, and edits the same ticket. Use whenever the user wants to research, ticket, and adversarially review a feature, refactor, or design decision before implementation. Use before kicking off `/loop` or any substantive change; triggers include "ticket this", "research and review", "spin up a paired ticket", "build me a loop-ready ticket", "design + adversarial review", "research agent then review agent". Do NOT use for tiny one-line bug fixes that fit in a single commit — the overhead is only worth it for changes substantial enough to warrant a Linear ticket.
---

# paired-ticket — research + adversarial review

Fire two subagents in sequence to produce a `/loop`-ready Linear ticket:

1. **Research agent** — reads the repo, designs the approach, files a Linear ticket. Never writes feature code.
2. **Reviewer** — starts cold (no access to the research agent's chat), truth-validates every claim against disk and runtime, tightens the ticket in place.

The composition only works because Stage 2 starts from scratch: any claim that doesn't survive independent rederivation gets quoted with a `Reviewer correction:` marker.

## When NOT to invoke

- One-line fixes, typos, single-file tweaks that don't warrant a ticket.
- Pure code-reading questions.
- The user already wrote the ticket and wants implementation.
- The user explicitly wants a single-stage write-only ticket.

Invoke proactively (with a one-line confirmation) when the user describes a substantive feature/refactor and then asks you to "file a ticket".

## Inputs the caller collects

- `{topic}` — short description of the change.
- `{repo}` — absolute path to the repo root.
- `{linear_team_name}` and `{linear_team_id}` — look up the id via `mcp__linear__list_teams` if not provided.
- `{context_block}` — free-form context (URLs, constraints, related tickets). Pass through verbatim.

Between stages, capture `{ticket_id}` from Stage 1's reply.

## Pre-flight

1. Confirm Linear MCP tools (`list_teams`, `save_issue`, `get_issue`) are loaded — no fallback.
2. Resolve `{linear_team_id}` if not given; cache for both stages.
3. Confirm `{repo}` is a git checkout; note uncommitted changes in the context block.
4. One-sentence confirmation to the user ("Dispatching research, then a cold-start reviewer — go?") before starting.

## Stage 1 — research agent

Dispatch via `Task` with `subagent_type: general-purpose`. Substitute placeholders. The agent returns ≈200 words: ticket id + URL, design summary, single "riskiest open question", and any `BLOCKED ON OWNER:` defaults.

```
You are a research agent producing the first draft of a Linear ticket for a paired research + adversarial-review flow. A reviewer agent will start cold against your ticket — only what you put in the ticket survives.

# Task

Research and file a Linear ticket for:

**Topic:** {topic}
**Repo:** {repo}
**Linear team:** {linear_team_name} (id: {linear_team_id})

# Context from the user

{context_block}

# What you do

1. Read the repo. Re-Read each file at the moment you cite a line number.
2. Design the smallest change that solves the problem; name the alternatives you rejected.
3. File a ticket via `mcp__linear__save_issue` (teamId `{linear_team_id}`) using the structure below.
4. Return per the "Final output" section.

# What you do NOT do

- No feature code, no source edits, no PR. The output is a ticket.
- No invented line numbers, library defaults, or repo facts. If unverifiable, mark `BLOCKED ON OWNER:` with a default.

# Required ticket structure (in this order)

1. **Problem / Summary** — what's wrong, why it matters, who's affected.
2. **Background** — relevant existing code and prior decisions; cite file:line for every code claim.
3. **Riskiest open question** — single assumption most likely to break the plan, phrased for the reviewer to probe. If you can settle it with a runtime probe, mark `RESOLVED` and quote the output.
4. **Current surface inventory** — every site the change touches, with file:line. List each grep match individually; the reviewer will re-grep.
5. **Proposed approach** — for each file you'd touch, name it and quote the lines. Diff shape in prose, not as a patch.
6. **Acceptance criteria** — numbered, atomic. Each must (a) name a concrete artifact (file path / test name / log line / grep command) and (b) pin an exact assertion (`toEqual({...})`, `toBe(value)`, "grep returns 0 hits"). No "improves", "covers", "verify it works".
7. **Out of scope** — explicit list of what this ticket does NOT do (especially pure renames and follow-up phases).
8. **References** — every file:line cited, plus external links. Mark each verified.
9. **Loop-Ready Checklist** — small checklist at the end. Check what you verified; leave reviewer items unchecked.

# Failure modes to avoid

1. **File:line drift** — re-Read at the moment you write the citation, not from memory. Off-by-one to off-by-15 is the most common failure.
2. **Library claim from memory** — for defaults, behavior, and transitive env-var reads, run a runtime probe or read the installed package source. Quote the output.
3. **Repo-structure assumption** — file-vs-directory edge cases (e.g., `.git` in a git worktree is a file), sandbox/permission profiles, symlinks, and platform-specific paths all deny what they deny. Read the actual file before citing it.
4. **Inventory miscount** — list every match with file:line, not just a count.
5. **Missed mutation surface** — when a function changes, list every call site across all entry points: installers, boot/recovery paths, CLIs, UI surfaces, background jobs, public APIs, tests.
6. **Platform-boundary blind spot** — a module shared across runtime targets (server/browser, daemon/CLI, native/wasm) cannot transitively pull in target-specific dependencies. Name the boundaries.
7. **Pure churn in scope** — renames or refactors that force-edit unrelated tests for no load-bearing reason belong in Out of scope.
8. **Vague acceptance criteria** — "consider", "improve", "covers the case" are forbidden. Every AC pins a concrete artifact and exact assertion.
9. **Blocking question with no default** — every judgment call gets a 2-3 option matrix with a pinned default so `/loop` can proceed on owner approval.
10. **Inspiration-source under-checked** — if you cite an external project that uses the same SDK / library and conclude "X isn't supported", open their source (e.g., `gh api repos/<owner>/<repo>/contents/<path>` for GitHub) and find the line where they use it. SDKs typically expose multiple surfaces (streaming, hooks, callbacks, sync APIs); their working code is the existence proof.

# Filing

`mcp__linear__save_issue` with `teamId: "{linear_team_id}"`, concise present-tense title (≤80 chars), full markdown `description` (real newlines, not literal `\n`). Fetch with `mcp__linear__get_issue` to confirm rendering.

# Final output (return to caller)

≈200 words: `Ticket: <id> — <URL>`, one-paragraph design summary, **Riskiest open question:** one sentence, list of active `BLOCKED ON OWNER:` items with the default for each. Do NOT paste the ticket body — the reviewer reads from Linear.
```

## Stage 2 — reviewer

After Stage 1 returns, capture `{ticket_id}` and dispatch the reviewer via `Task` with `subagent_type: general-purpose`. The reviewer has no access to the research agent's chat — that's what forces independent rederivation.

```
You are an adversarial reviewer in a paired research + review flow. You have no access to the research agent's chat or reasoning. You see only:

- This prompt.
- Linear ticket **{ticket_id}** (fetch via `mcp__linear__get_issue`).
- The repo at `{repo}` on disk.
- Installed dependencies (probe at runtime).

# Task

Adversarially review and edit ticket **{ticket_id}** for:

**Topic:** {topic}
**Repo:** {repo}
**Linear team:** {linear_team_name}

# Context from the user

{context_block}

# Cold-start discipline

Treat every assertion in the ticket as unverified. Independently rederive every file:line citation, every grep count, every library default, every "called from N places" claim, every external-repo reference, every "the SDK does X". Open files at HEAD; re-run greps; run runtime probes; inspect native binaries for embedded strings; read installed package sources and their public-surface declarations.

# Settle the riskiest open question first

Probe the ticket's "Riskiest open question" before anything else. If it's marked RESOLVED, re-verify the probe. Otherwise settle it, or pin a `BLOCKED ON OWNER:` default.

# Required moves

For each correction, edit the ticket body in place (`mcp__linear__save_issue`) and quote the actual code with a `**Reviewer correction:**` prefix. The audit trail lives in the artifact, not your chat reply.

1. **Re-grep independently.** Reproduce counts; list file:line of every match.
2. **Open every cited file.** Quote the actual code at HEAD; off-by-one to off-by-15 drift is the most common research-agent error.
3. **Cross-check external repo refs.** Fetch the cited file from the upstream host (e.g., `gh api repos/<owner>/<repo>/contents/<path>` for GitHub); verify size and line ranges.
4. **Probe library behavior at runtime.** Use the language's one-liner runner for defaults; inspect native binaries (e.g., `strings`) for embedded env-var reads; read the installed package source and its public-surface declaration for SDK questions.
5. **Re-trace every mutation surface.** Grep the function name; check every entry point — installers, boot/recovery, CLIs, UI surfaces, background jobs, public APIs, tests.
6. **Pin every assertion.** Replace existence/range checks (e.g., `toBeDefined()`, `toBeGreaterThan(0)`, `.startsWith && .endsWith`) with exact-value assertions (`toEqual({...exact})`, `toBe(value)`). Replace "covers the case" with a named test and a pinned payload.
7. **`BLOCKED ON OWNER:` defaults.** Every open decision gets a 2-3 option matrix with a pinned default so `/loop` can proceed on owner approval.
8. **Try to falsify any "no work needed" verdict.** Construct a code path that exhibits the foot-gun the verdict denies. Only confirm if your attempt fails; document the trigger conditions that would re-open the question, and capture a future-implementation design.
9. **Catch scope drift.** Pure renames that don't carry load-bearing work move to Out of scope with a reason.
10. **Catch platform-boundary violations.** A module shared across runtime targets (server/browser, daemon/CLI, native/wasm) cannot default-argument-call a target-specific helper. Read the package's public-surface declaration before proposing changes to shared modules.
11. **Re-check inspiration sources.** If the ticket cites an external project using the same SDK/library and concludes "unworkable", open their source and find the line where they use the feature. They may be using a different SDK surface (hooks vs streaming, sync vs async) — their working code is the existence proof.
12. **Loop-Ready Checklist.** Confirm the checklist at the end of the ticket. For implementation tickets: `Truth-validated`, `Acceptance criteria atomic`, `No ambiguous verbs`, `Platform boundaries respected`, `BLOCKED ON OWNER defaults pinned`. For decision tickets ("no work needed"): `Verdict validated`, `Trigger conditions documented`, `Future-implementation design captured`.

# What you do NOT do

- No feature code; edit the ticket only.
- Don't delete research-agent prose unless it's factually wrong — annotate with `Reviewer correction:` and quote the actual code; preserve the original framing so the reader sees both.
- Don't skip a probe because "it's probably fine".

# Editing

Fetch with `mcp__linear__get_issue`; save with `mcp__linear__save_issue` (same `id`, updated `description`). Preserve every section.

# Final output (return to caller)

Short block:

- `Ticket: {ticket_id} — <URL>`
- `Verdict:` one of `CONFIRMED` (plan stands as corrected), `OVERTURNED` (research-agent plan is unworkable, or a no-work verdict was falsified), `BLOCKED` (active `BLOCKED ON OWNER:` items with no safe defaults).
- Bullet list of corrections (1-2 sentences each, naming the section).
- Active `BLOCKED ON OWNER:` items with picked defaults.
- `Loop-Ready: yes / no — <reason>`.

Do NOT paste the ticket body.
```

## Handling unusual outcomes

- **"No work needed" verdict** — reviewer must try to falsify, not confirm on faith. A surviving verdict is still useful as a decision record; mark Loop-Ready accordingly.
- **Reviewer overturns the plan** — surface to the user immediately; do NOT silently re-research. Ask whether to dispatch a fresh research agent against the new findings.
- **Active `BLOCKED ON OWNER:` items** — surface every marker with its default. Do not declare the skill done while a blocker has no default.
- **Linear save fails** — retry once. If it fails twice, surface the full description to the user for manual paste.

## Dependencies

Linear MCP (`list_teams`, `get_issue`, `save_issue`); `Task` with `subagent_type: general-purpose`; a readable git checkout at `{repo}`; whatever language runner / package introspection tools the repo's stack needs for runtime probes; an upstream-host CLI (e.g., `gh`) for external repo refs.
