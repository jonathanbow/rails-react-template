---
description: Review the app (or a branch/PR) and write a verified findings report to requirements/
argument-hint: [branch, PR number, or git range — blank for the whole app]
allowed-tools: Read, Grep, Glob, Write, Agent, AskUserQuestion, ReportFindings, Bash(git log:*), Bash(git diff:*), Bash(git show:*), Bash(git status:*), Bash(git branch:*), Bash(git merge-base:*), Bash(git ls-files:*), Bash(gh pr view:*), Bash(gh pr diff:*), Bash(bin/brakeman:*), Bash(bin/bundler-audit:*), Bash(bin/rubocop:*), Bash(npm run check), Bash(npm run lint), Bash(npm run format), Bash(npm audit:*), Bash(ls:*)
---

You are reviewing a Rails 8.1 + Inertia Rails + React/TypeScript application. Produce an actionable, **verified** findings report at `requirements/review-<YYYY-MM-DD>.md` (today's date). This is a read-only review: do not fix anything, do not switch branches, do not commit, and do not run autocorrecting tools (`bin/rubocop -A`, `npm run lint:fix`, `npm run format:fix`). The only file you write is the report.

The scope is: $ARGUMENTS

`CLAUDE.md` is already loaded; do not re-read it. Other sessions may share this checkout, so run `git branch --show-current` once and review what is checked out rather than assuming.

---

## Step 1 — Fix the scope and read the prior reviews

- **Blank scope**: review the whole application, with extra attention on what changed since the most recent review. Find that review (the newest `review-*.md` in `requirements/` or `requirements/done/`), take its date, and use `git log --since=<date> --oneline` and `git diff --stat <commit-at-that-date>..HEAD` to see where the churn is.
- **A branch, PR number, or git range**: review only that diff (`git diff main...<branch>`, `gh pr diff <n>`, or the range given), plus whatever the changed code calls into or is called from. Read whole changed files, not only hunks, because a bug is often in how the new code meets the old.
- If the scope is ambiguous (a name that matches both a branch and a PR, a range that doesn't resolve), ask with `AskUserQuestion` rather than guessing.

Read the most recent one or two prior reviews. Use them to:

1. Carry over a short "Resolved since the last review" list, each item verified in the code before you list it.
2. **Not re-raise** anything the project already decided against: items a prior review recorded as declined or accepted, and decisions recorded in your auto-memory. A finding that was deliberately rejected is not a finding.
3. Re-raise an open prior finding only if it is still present, and say it is carried over.

---

## Step 2 — Tooling baseline

Run these (independent commands can run in one batch) and record the result of each in the report header. They are the same checks `bin/ci` runs, minus the test suite:

- `bin/brakeman -q`
- `bin/bundler-audit`
- `bin/rubocop` (no `-A`)
- `npm run lint`, `npm run format`, `npm run check`
- `npm audit`

Only offences in code within the review scope are findings; clean results are one line in the header. If a tool fails for reasons unrelated to the scope (a pre-existing failure, an unreachable audit service), note it in the header as pre-existing and move on rather than treating it as a finding or stalling. Do not run the full spec suite; that is `bin/ci`'s job.

For routes: if `config/routes.rb` changed in scope, check that `app/javascript/routes/**` changed with it (`git diff --stat`), and grep `.tsx` files for hardcoded URL strings that should be `@/routes` imports. Do not regenerate the files yourself.

---

## Step 3 — Review in parallel

Split the review into independent slices and launch one `general-purpose` subagent per slice, **all in a single message** so they run concurrently. Suggested slices (merge or drop any that the scope doesn't touch):

1. **Controllers, routes & auth**: sections 1 and 5 below, as they apply to `app/controllers/**` and `config/routes.rb`.
2. **Models, migrations & queries**: section 2.
3. **Security & PII**: section 3.
4. **Jobs, services & external integrations**: section 4.
5. **Frontend**: section 6 over `app/javascript/**` (excluding `routes/**` and `components/ui/*`).
6. **Specs & house rules**: section 7.

Do not use `Explore` for review slices: it locates code, it doesn't audit it.

Each subagent prompt must be self-contained: give it the scope, the section(s) of this checklist it owns, the instruction to read whole files and follow call sites, and the instruction that it is **read-only** (no edits, no writes, no autocorrect). Ask it to return, for each candidate finding: category, file and line, severity, the issue, the concrete failure scenario (inputs or state, and what goes wrong), and a suggested fix, plus a confidence of high or low. Tell it to return nothing for an area with no problems rather than padding.

Meanwhile, do not duplicate their searches. Use the time to read the pieces of the app that cut across slices (the shared base controllers, `Current`, the Inertia share, `types/index.ts`).

---

## Step 4 — Verify before you report

Subagent output is a list of candidates, not findings. For every candidate:

1. Open the cited file and confirm the code is what the candidate says it is, at that line. Drop anything you cannot confirm.
2. Confirm the failure scenario is reachable: trace the caller, the route, and whatever guard sits in front of it (authentication, `require_admin`, validations, DB constraints). A problem already prevented by a guard elsewhere is not a finding.
3. Check it against the recorded decisions from Step 1 and against `CLAUDE.md`. If the code follows a convention the project states, it is not a finding even if it looks unusual.
4. De-duplicate: merge candidates describing the same root cause into one finding that lists every location.
5. Set severity using the rubric below. Be honest about it: do not inflate to look thorough.

**Severity**
- **High**: exploitable security flaw, PII exposure, data loss or corruption, a wrong result users will hit, or a production-breaking defect.
- **Medium**: a real defect or maintainability problem with limited blast radius or a workaround: an N+1 on a page that will be hit, a missing constraint, a convention violation that will spread if copied, missing test coverage for risky behaviour.
- **Low**: style, naming, small duplication, polish.

Write only findings that exist in the code. Do not invent hypothetical issues, and do not pad a category to fill the table; zero is a fine number.

---

## Review checklist

Apply `CLAUDE.md` and the files in `.rules/` that match the code under review. Authentication Zero and shadcn idioms in the auth/settings/layout code are intentional (see "What this is" in `CLAUDE.md`); judge new domain code against the stated conventions, not against how the scaffold looks.

### 1. Rails & Inertia

- Controllers doing more than parameter handling, authorization, and orchestration; logic that belongs in a model, scope, or (only when it spans models or is genuinely complex) a service. Do not ask for a service object for trivial logic.
- `before_action` used for anything other than authentication or authorization; side effects hidden in filters.
- `as_json(only: [...])` allowlists that are missing (raw models or unfiltered `as_json` going to the page), broader than the page needs, or out of sync with the matching interface in `app/javascript/types/index.ts` in either direction.
- `inertia_share` carrying page-specific data (only `auth` belongs there).
- Mutating actions that render a page instead of `redirect_to ... notice:/alert:` or `inertia: { errors: }`.
- A rendered page whose component is not at `app/javascript/pages/<controller>/<action>.tsx`, or a prop the component takes that the action never passes.
- Hand-edits to `app/javascript/routes/**` or `components/ui/*`; hardcoded URL strings instead of `@/routes` imports; routes changed without regenerated route files.
- Mutations from the frontend via raw `fetch`/`axios` instead of Inertia's `<Form>` or `router.*`.

### 2. Active Record & database

- N+1 queries in props-building code (loops over associations without `includes`/`preload`/`eager_load`), `find` inside loops. Weigh against the expected data volumes in your memory (about 40 active flights, 500+ archived: active lists are never paginated, archived ones are).
- Queries built in controllers that should be model scopes; repeated query shapes that should be a named scope.
- Callbacks other than the sanctioned exceptions (`before_validation` normalisation, invariants that cannot be a DB constraint); side effects (mail, jobs, API calls) triggered from callbacks instead of called explicitly.
- `update_attribute`/`update_column` skipping validations without a reason; `has_many`/`has_one` without a considered `dependent:`.
- Validations without a backing DB constraint where one is practical (`null: false`, unique index, foreign key); foreign keys and frequently queried columns without an index; schema and data changes mixed in one migration; unsafe migrations on tables that will be large (there is no `strong_migrations`, so judge by hand: locking operations, backfills in the same migration).
- `db/schema.rb` out of step with the migrations.

### 3. Security & PII

- Mass assignment: `permit` accepting ownership fields (`user_id`), roles, or other sensitive attributes; ownership not set server-side or queries not scoped through the right association (an authenticated user reading or changing another record by id).
- Actions reachable without authentication, or admin-only actions missing `require_admin`. Only `SessionsController#new/create` and `TwoFactorAuthenticationChallengesController#show/create` should skip `authenticate`; `AccountingDocumentCallbacksController` subclasses `ActionController::Base` and carries no session or CSRF machinery, so check that it authenticates the caller another way (signature or token verification, constant-time comparison, replay handling).
- Passport and other PII (encrypted attributes, authenticated downloads), 2FA codes, tokens, and passwords appearing in logs, error reports (Rollbar), flash messages, `as_json` output, or exception messages. Check `filter_parameters` and any Rollbar scrubbing against newly added sensitive params.
- Raw SQL or string interpolation into `where`/`order`/`execute`; `send`/`constantize`/`to_proc` on user input; `redirect_to` on user-supplied URLs (use the existing safe-return helper); file handling and uploads (content-type trust, path handling, size limits).
- `dangerouslySetInnerHTML` on user-supplied or externally sourced content without sanitisation.
- CSRF protection disabled outside the callback controller; SSRF or unbounded outbound requests to user-supplied URLs.
- Brakeman, `bundler-audit`, and `npm audit` results from Step 2 that fall within scope.

### 4. Background jobs, services & integrations

- Slow or fallible work (email, Xero and other external APIs, PDF/CSV processing) done inside the request cycle instead of an Active Job on Solid Queue.
- Jobs that are not idempotent, take records rather than ids, hold business logic in `perform`, or lack `retry_on`/`discard_on` for transient failures; jobs enqueued inside a transaction before it commits.
- Third-party calls not behind an app-owned wrapper (see `.rules/abstract_third_party_interfaces.md`), without timeouts, or with retry middleware that could double-post a non-idempotent call.
- Services that have a hidden side effect, more than one public entry point, or exist to wrap a single line.
- Error handling: `rescue Exception`, bare `rescue` swallowing errors, rescue used for control flow, failures that vanish without a log or user-visible message.

### 5. DRY & structure

- The same helper, query, or authorization check copy-pasted across controllers or models. Extract only once the third copy exists ("three similar lines beat an early abstraction"), so flag duplication that has reached that point, not every pair.
- Models or controllers that have grown to several responsibilities; speculative abstractions and extension points nothing uses; dead code, dead routes, routes without an action, `resources` without `only:`/`except:`, `get` routes that mutate, nesting deeper than two levels.

### 6. Frontend (React/TypeScript)

- Derived state, formatting, or business logic inline in a page component instead of `lib/` or `hooks/` (`.rules/no_inline_computation_in_page_components.md`); mutations triggered from presentation helpers.
- `useEffect` fetching or syncing data that is already an Inertia prop; state that mirrors a prop.
- Hand-rolled UI that duplicates a `components/ui/*` primitive; ad-hoc styles where the file's Tailwind conventions apply.
- `any`, `as unknown as`, or `@ts-ignore` covering a real type mismatch; types duplicated instead of imported from `@/types`.
- Form labels not tied to their inputs (`.rules/form_labels_match_inputs.md`); inputs with no error display for server-returned errors.
- Debug output (`console.log`, `debugger`) left in committed code; unused props, imports, and variables.
- Do **not** report a lack of automated frontend tests. Frontend testing is manual by design.

### 7. Tests & house rules

- Changed or new backend behaviour (models, requests, jobs, services) without a spec that pins it; bug fixes without a regression test; specs that assert implementation rather than behaviour or over-mock.
- Specs that break `.rules/` (setup in `before`, self-contained contexts, `with`/`without` wording) or use FactoryBot instead of `spec/fixtures/`. Fixtures with hard-coded dates that will expire.
- String-ordering specs that depend on the local collation.
- Anything that adds Capybara, Selenium, or `spec/system/**`.
- Comments in `app/models`, `app/controllers`, `app/services`, and `app/jobs` that restate what a spec or the code already says (see "Keep application code close to comment-free" in `CLAUDE.md`). Functional directives and comments that forbid a plausible future change are exempt.
- `Metrics/MethodLength` and the other rules in `.rubocop.yml`, `.rules/no_shorthand_variables.md`, `.rules/avoid_law_of_demeter_violations.md`; `is_*` predicate names; more than one class per file.

---

## Step 5 — Write the report

Create `requirements/review-<YYYY-MM-DD>.md`. Number every finding (`F1`, `F2`, ...) in priority order so they can be referred to from a plan or PR.

````markdown
# Code Review — <YYYY-MM-DD>

Scope: <whole app with focus on changes since <date>, or the branch/PR/range reviewed>, on branch `<branch>` at `<short sha>`.

Tooling baseline: <one or two lines: brakeman, bundler-audit, rubocop, eslint, prettier, tsc, npm audit; say which were clean, and note any pre-existing failures>.

**Resolved since the last review, verified in code and not re-reported:**
- <item>

<Optional: one line on anything deliberately not re-raised because an earlier review or plan declined it.>

## Summary

| Category | High | Medium | Low | Total |
|---|---|---|---|---|
| Rails & Inertia | N | N | N | N |
| Frontend (React/TypeScript) | N | N | N | N |
| Active Record & Database | N | N | N | N |
| Security | N | N | N | N |
| DRY / Refactoring | N | N | N | N |
| Routing & Authentication | N | N | N | N |
| Background Jobs & Async | N | N | N | N |
| Tests & House Rules | N | N | N | N |
| Code Style | N | N | N | N |
| **Total** | **N** | **N** | **N** | **N** |

## Findings

### F1 · [CATEGORY] Short title of issue

- **File**: `path/to/file.rb:line` (list every location for a merged finding)
- **Severity**: High / Medium / Low
- **Status**: New, or Carried over from <review date>
- **Issue**: What is wrong and the concrete scenario in which it bites (inputs or state, and the wrong outcome).
- **Fix**: A concrete change, with a snippet when it helps. Name the spec that should pin it.

---
(repeat for each finding, ordered High, then Medium, then Low)

## Recommended Priority Order

1. High severity findings, with a one-line reason each.
2. Medium findings grouped into themes that could each be one `/plan-dev` plan (for example "N+1s on the flight pages").
3. Low findings last, batched into a single clean-up.
````

If a category has no findings, its row is zeros and you add nothing for it under Findings. Put the category names in the report exactly as in the table so reports stay comparable over time.

---

## Step 6 — Hand off

1. If the `ReportFindings` tool is available, call it once with the findings, most severe first (at most 32; keep the full list in the file). The file stays the source of truth. Do not also print the findings as text.
2. In chat, give a short summary: the totals by severity, the High findings in one line each, and the path of the report. Do not paste the report.
3. Do not commit the report, move it, or start fixing anything. Offer to turn a chosen group of findings into a plan with `/plan-dev`, and leave that choice to the user.

## Rules

- Verify before you cite: every file, line, method, and route named in the report must be one you opened in this session.
- Report only what is in the code. A review with three real findings beats one with thirty plausible ones.
- Scope discipline: for a branch or PR review, pre-existing problems elsewhere in the app are out of scope unless the change makes them worse.
