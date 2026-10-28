---
description: Implement a plan from requirements/ with a red/green TDD cycle per step
argument-hint: <plan-file>
---

You are implementing a feature for a Ruby on Rails web application. Follow these steps in order, completing each fully before moving to the next.

The plan file to implement is: $ARGUMENTS

If the plan file above is empty, list the files in `requirements/` (not `requirements/done/` or `requirements/deferred/`), ask the user which one to implement (with `AskUserQuestion`, or a plain question), and wait for the answer before doing anything else. Use their answer as the plan file wherever `$ARGUMENTS` appears below.

---

## Step 1 — Read context and plan

Read the plan file `$ARGUMENTS` before writing a single line of code. `CLAUDE.md` is already loaded; do not re-read it.

After reading, summarise in 2–3 sentences: what the feature does, which files will be created or modified, and any constraints from the plan you want to flag before starting.

Check the plan's "Depends on" section. If it names unmerged work (a PR, branch, or other plan file), stop and tell the user this plan builds on unmerged work, and wait for their decision before branching. If they want a stack, follow `.rules/stacked_prs.md`.

Note whether `$ARGUMENTS` is a path under `requirements/` (and not already under `requirements/done/`; a plan under `requirements/deferred/` is eligible, and Step 6 moves it to `done/`). This determines whether Step 6 applies later.

---

## Step 2 — Create a feature branch

First, check the working tree with `git status` and note the current branch. If there are uncommitted changes, stop and ask the user what to do with them; do not stash, discard, or carry them onto the new branch. Other sessions may share this checkout, so never assume the branch is what you left it on.

Then switch to `main` and pull the latest from remote:

```bash
git checkout main
git pull origin main
```

Derive a short kebab-case branch name from the plan file name or the feature title (e.g. `feature/add-task-comments`).

Then create the feature branch from up-to-date `main`:

```bash
git checkout -b <branch-name>
```

Tell the user the branch name.

---

## Step 3 — Work through the plan one step at a time

For each step in the plan, follow the TDD cycle below before moving to the next step. Never move to the next step while tests are red.

Before starting a step, read the files in `.rules/` that apply to the code it touches (for example the test-setup rules before writing a spec, or the page-component rules before editing a `.tsx` page). Do not read all of them up front.

If you find an unrelated bug while working, do not fix it on this branch; note it for the user (`.rules/bug_fixes_in_isolated_branches.md`).

If a step involves finding many call sites or comparing against existing patterns across the codebase, delegate that search to `Explore` subagents and work from their conclusions. Keep the TDD cycle itself in this session.

If a step turns out to be wrong or impossible (a file or method it names does not exist, it conflicts with an existing pattern, or the plan contradicts itself), stop and report what you found. Do not improvise a different design; the plan may have been written a while ago. Wait for the user's decision before continuing.

### Which path a step takes

Follow the plan's own verification notes. A step the plan tags "manual verification" takes the no-spec path below. A step that names a spec file takes the spec path. If a step has neither, use the nature of the change: migrations, routes, and views take the no-spec path; models, controllers, and services take the spec path.

### For steps that have a spec (models, controllers, services, request specs):

1. **Write the spec first** — do not write any implementation yet
2. **Run the spec** — `bin/rspec <path>` — confirm it fails (red). If it passes without implementation, the spec is wrong; fix it first
3. **Write the implementation** — follow the conventions in CLAUDE.md. If the step changes the props a controller passes, update the matching TS types in `app/javascript/types` in the same step
4. **Run the spec again** — confirm it passes (green). Fix failures before continuing; never skip or delete a failing test
5. **Run lint** — `bin/rubocop -A <the Ruby files changed in this step>` (not the whole repo, so the commit stays atomic); for any JS/TS touched in this step also run `npm run check` and `npm run lint:fix` — fix any remaining offences
6. **Commit** — one commit per plan step, only when green. Before committing, confirm with `git branch --show-current` that you are still on the feature branch

### For steps with no spec (migrations, routes, views, or steps tagged "manual verification"):

1. **Implement** the migration, route, or view
2. If a migration: run `bin/rails db:migrate` and confirm the schema matches the plan
3. If routes changed: run `bin/rails typelizer:generate:refresh` to regenerate `app/javascript/routes/**`
4. If a view: do not launch the server or drive a browser yourself — the user runs the app via `bin/dev` and verifies the UI themselves in Step 5
5. **Run lint** — `bin/rubocop -A <the Ruby files changed in this step>`; for view/TS changes also run `npm run check` and `npm run lint:fix`
6. **Commit** — first confirm with `git branch --show-current` that you are still on the feature branch

---

## Step 4 — Final check

After all steps are complete, run `bin/ci` (the same checks CI runs: brakeman, bundler-audit, rubocop, eslint, prettier, tsc, and the full rspec suite).

Report the results and confirm everything passes. Fix any failures before proceeding.

---

## Step 5 — Browser testing (UI steps only)

If the plan does not include any views or UI changes, skip this step entirely and go straight from Step 4 to Step 6.

If the plan includes any views or UI changes, tell the user:

1. The branch name
2. How to start the server: `bin/dev` (a dev server may already be running on :3000)
3. The specific URL(s) to visit
4. A short checklist of what to verify (happy path + edge cases from the plan, including the plan's "manual verification" items)

Then ask: **"Please test the feature in your browser and let me know if anything needs changing, or if it looks good."**

If changes are needed: implement them, re-run `bin/ci`, then return to this step.

Once the user confirms it looks good, move to Step 6.

---

## Step 6 — Move plan file to `done` (if applicable)

Skip this step entirely if `$ARGUMENTS` is not a path under `requirements/` — e.g. an ad-hoc feature description, or a plan file already under `requirements/done/`.

Otherwise, ask: **"Feature complete — move `<plan-file>` to `requirements/done/`?"** and wait for the reply.

- If confirmed:

  ```bash
  git mv <plan-file> requirements/done/<plan-file-basename>
  git commit -m "docs: move <plan-file-basename> to done"
  ```

- If declined, leave the file where it is and finish without moving it.

---

## Step 7 — Offer to push and open a PR

Do not push or open a PR on your own. Ask: **"Push `<branch-name>` and open a PR against `main`?"** and wait for the reply.

- If confirmed: `git push -u origin <branch-name>`, then open the PR with `gh pr create` against `main`, with a description summarising the feature and linking the plan file.
- If declined, finish without pushing.

Base the PR on `main` unless the user explicitly asks otherwise.

---

## Commit format

Use the project's commit notation from `.rules/commit_messages.md`. Each step's commit should be atomic and leave the suite green.
