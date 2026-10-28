---
description: Produce a numbered implementation plan in requirements/ (no code)
argument-hint: <feature description>
allowed-tools: Read, Grep, Glob, Write, Agent, AskUserQuestion, Bash(ls:*)
---

You are a senior Rails developer producing an implementation plan. Do NOT write any code or make any file changes — this command outputs a plan document only.

The feature request is: $ARGUMENTS

## Your task

1. If the feature request above is empty, ask the user what they want planned (with `AskUserQuestion`, or a plain question) and wait for the answer before doing anything else.
2. Explore the codebase to understand the relevant context: existing models, controllers, Inertia page components (`app/javascript/pages/**`), routes, concerns, and helpers that relate to the requested feature. For broad searches (every usage of a model, all similar existing features, naming conventions across directories), delegate to `Explore` subagents and work from their conclusions rather than reading everything yourself; read the key files directly once you know which they are.
3. Determine the next plan number by listing files in `requirements/`, `requirements/done/` and `requirements/deferred/` and finding the highest `NNNN-` prefix across all three directories, then incrementing by 1 (pad to 4 digits). If no plan files exist in any of them, start at `0001`.
4. Derive a concise kebab-case feature name from the request (e.g. `task-due-dates`, `user-invitations`).
5. Write the plan to `requirements/NNNN-<feature-name>.md` using the structure below.
6. Report the file path to the user when done.

## Plan document structure

```markdown
# NNNN — <Human-readable feature title>

## Overview

One paragraph describing what the feature does and why it's needed. Reference any relevant existing parts of the codebase.

## Depends on

Any unmerged work this plan builds on (a PR, branch, or other plan file), or "None." This tells the implementer whether the plan can start from the main branch. Flag a dependency, but do not decide how the work is branched or stacked.

## Scope

What is explicitly IN scope for this feature, and what is OUT of scope (deferred to later).

## Affected files

List every file expected to be created or modified, with a one-line note on what changes.

| File | Change |
|------|--------|
| `app/models/...` | new model or association |
| `app/controllers/...` | new controller or action |
| `app/javascript/pages/<controller>/<action>.tsx` | new or modified Inertia page component |
| `app/javascript/types/index.ts` | update TS interface to match controller's `as_json` shape |
| `db/migrate/...` | new migration |
| `config/routes.rb` | new routes (note if `bin/rails typelizer:routes` needs to be re-run) |
| ... | ... |

## Data model changes

If new models or migrations are needed, describe the columns, types, and associations. Note any indexes required. If none, write "None."

## Implementation steps

Ordered steps a developer should follow. Each step is implemented as one test-then-code cycle and committed on its own, so size it to be a single coherent commit: small, independently testable, and leaving the app working. Apply the conventions in `CLAUDE.md` concretely rather than generically, and name the exact file or method each applies to. Examples of the kind of detail to include, where relevant to the feature:

- Which authentication and authorization checks the new actions need, using the mechanism the app already uses (a `before_action`, a role check, a policy), and whether any action must opt out.
- Strong parameters in the controller; ownership and foreign keys set server-side, never taken from params; queries scoped through the appropriate association.
- Where the logic lives (model, scope, validation, or a service) and why, per the app's stated preference.
- Side effects called explicitly by the caller rather than hidden in callbacks, unless `CLAUDE.md` allows an exception.
- Database constraints (`null: false`, unique indexes, foreign keys, indexes on queried columns) that back each validation.
- N+1 risks on any new list or association rendering, and the `includes`/`preload` that avoids them.
- For Inertia pages: which props the action passes, the matching TypeScript interface update alongside any change to a controller's serialized shape, and errors returned via the app's established redirect-with-errors pattern.
- Re-running any code generators the app uses (e.g. generated route helpers) after the change that requires it.
- Following any rules in `CLAUDE.md` about comments, abstractions, or generated directories that should not be hand-edited.

Every step must say how it is verified, following the testing approach in `CLAUDE.md`. For a step with automated coverage, name the spec file to create or extend, the fixtures or setup it needs, and the behavior it pins; the failing test comes before the production code in that step. For a step the project verifies manually (for example UI work when `CLAUDE.md` says frontend testing is manual), tag it "manual verification" and say what to check in the browser. Bug fixes include a regression test.

1. ...
2. ...
3. ...

## Test plan

A summary of the verification above, grouped by spec file or manual check: which behaviors are pinned automatically (validations, authorization, edge cases, error paths) and which are checked manually. Call out any existing specs or fixtures that the change will break or require updating. Do not add test types that `CLAUDE.md` rules out.

## Key design decisions

Call out any non-obvious choices made in this plan and why (e.g. service object vs fat model, how auth is handled, how ownership is enforced, redirect-with-flash vs re-rendering with `inertia: { errors: ... }`).

## Out of scope / follow-on work

Anything explicitly deferred and why.
```

## Handling ambiguity

First try to resolve every ambiguity yourself from the request and the codebase: look at how similar features were built and follow that precedent. Then sort whatever remains into two kinds:

- **Minor gaps with an obvious, low-cost default** (naming, column types, where a button goes, anything easily changed during review): pick the default and record it in an optional "Assumptions" section directly after Scope, one line each, so the requester can veto it.
- **Blocking ambiguities**, where the plausible answers lead to different designs and a wrong guess would send the implementation in the wrong direction: do not guess. Ask the requester directly with the `AskUserQuestion` tool (up to four questions per call), putting your recommended option first and marked "(Recommended)". Once answered, fold the answers into the plan and carry on — no Open Questions section is needed.

Only if you cannot ask interactively (the tool is unavailable or the question goes unanswered), fall back to the document: add an "Open Questions" section at the top of the plan document (before Overview) and stop there — do not write the rest of the plan until the questions are answered. For each open question, give your recommended answer and why, so the requester can simply confirm it.

```markdown
## Open Questions

> These questions must be answered before the plan can be completed.

1. **[Question title]** — Describe the ambiguity and why it blocks the plan. If there are two plausible interpretations, name both so the requester can pick one. **Recommendation:** which one you would choose, and why.
2. ...
```

Triggers for this section:

- The requirement implies two or more mutually exclusive designs (e.g. "users can share projects" — shared ownership, or viewer access, or duplicate/fork?)
- A key entity or relationship is undefined (e.g. "add notifications" — in-app, email, both?)
- Scope is unclear and the right answer changes the affected-files list significantly
- A business rule is ambiguous (e.g. "only admins" — which admin role? global admin or project admin?)

If you can determine the plan from the codebase and the request, plus low-cost defaults recorded as assumptions, omit the Open Questions section entirely.

## Rules

- Do not implement anything. Write the plan file and stop.
- Base all decisions on what actually exists in the codebase — do not invent classes or patterns that aren't there.
- Follow CLAUDE.md conventions in all recommendations (service objects vs concerns, auth patterns, ActiveRecord ownership scoping, etc).
- Keep steps concrete and specific — reference real file paths, class names, and method signatures where known.
- Verify before you cite. Every file, class, method, route, or column the plan names must be one you have read in this session, with a path (and line number where useful), or be explicitly marked as new. If you haven't confirmed something exists, check it or leave it out.
- For a blocking ambiguity, ask with `AskUserQuestion` before writing the plan. If you cannot ask, write only the Open Questions section and stop — do not fabricate the rest of the plan. Do not stop for minor gaps; assume a sensible default and list it under Assumptions.
