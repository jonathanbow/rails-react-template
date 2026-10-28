You are cutting a production release for this Rails + Inertia application. Follow the steps in order, completing each fully before moving on.

An optional tag name may be supplied: $ARGUMENTS. Leave it blank to let the workflow auto-generate `vYYYY.MM.DD.N`.

## How releasing works here

Railway deploys from the **`release`** branch, never from `main`. Merging a PR into `main` deploys nothing. A release fast-forwards `release` to main's tip and tags it — that push is what Railway watches, and Railway's "Wait for CI" setting holds the deploy until [`ci.yml`](.github/workflows/ci.yml) passes on the release commit.

The mechanism is the **Release** workflow (`.github/workflows/release.yml`), dispatched against `main`. Never push `release` by hand, and **never** use `--force`: no-force means git rejects anything that isn't a fast-forward, so production can only move forward along main's history. That guarantee is the whole safety model — preserve it.

Read `README.md`'s "Deployment" section if anything below is ambiguous.

---

## Step 1 — Pre-flight checks

```bash
git fetch origin --tags
git status --short
git log --oneline origin/release..origin/main
```

Verify all of the following. Stop and tell the user if any fail:

1. **Working tree is clean** — a dirty tree isn't fatal (the release is cut from `origin/main`, not local state), but flag it so the user knows uncommitted work is not shipping.
2. **There is something to ship** — if `origin/release..origin/main` is empty, `release` already points at main's tip. Report that and stop; there is nothing to release.
3. **`release` is an ancestor of `main`** — `git merge-base --is-ancestor origin/release origin/main`. If this fails, the fast-forward will be rejected: `release` has commits that main does not. Do not try to work around it; report it and stop so the user can decide (usually it means a previous release shipped something never merged back).
4. **Local `main` matches `origin/main`** — if the user has unpushed commits on local `main`, say so explicitly. They will not be in the release.

---

## Step 2 — Work out what is shipping

Summarise the release for the user. Group commits by the pull request that brought them in:

```bash
git log --merges --format='%s%n    %b' origin/release..origin/main
git log --oneline origin/release..origin/main
```

Then check for the things that need attention *before* the deploy, not after:

**Migrations** — Railway runs `bin/rails db:prepare` as its pre-deploy command, so migrations run automatically and a failed migration fails the deploy while the previous version keeps serving.

```bash
git diff --name-only origin/release..origin/main -- db/migrate
```

If there are any, read them. Call out anything destructive or non-reversible (dropping/renaming columns or tables, `null: false` added to a populated column without a default, data backfills) — those need a deliberate decision, because the old container is still serving while the migration runs.

**New environment variables** — Railway variables are dashboard configuration, not in version control. A release that reads a variable nobody has set will boot-loop or fail its healthcheck.

```bash
git diff origin/release..origin/main | grep -nE '^\+.*ENV(\[|\.fetch)'
```

If any appear, confirm with the user that they are set in the Railway production environment before continuing.

**Anything else that isn't code** — new gems needing system packages, `Dockerfile` changes, `railway.json` changes, changes to `config/recurring.yml` or queue configuration. Mention them; don't assume they're handled.

Write the summary as: number of PRs, a one-line description of each, then a short "Needs attention" list (or "nothing flagged").

---

## Step 3 — Verify main is green

CI does not run on `main` — only on pull requests and on pushes to `release`. So a bad merge is not caught until the release commit is already on `release`, and the README's failure mode applies: Railway marks the deployment `SKIPPED`, the running version keeps serving, but `release` is left pointing at a bad commit.

Run the full suite locally against main to catch that first:

```bash
bin/ci
```

If it fails, do not cut the release. Report the failure. If the failure is pre-existing and unrelated to what is shipping, say so plainly and let the user decide whether to proceed — don't decide for them.

If the user has explicitly asked to skip this, skip it and note in the final report that the release was cut unverified.

---

## Step 4 — Confirm with the user

Show the Step 2 summary and the tag that will be used (`$ARGUMENTS` if supplied, otherwise "auto-generated `vYYYY.MM.DD.N`"), and ask for an explicit go-ahead. **Do not dispatch the workflow without it** — this deploys to production.

---

## Step 5 — Cut the release

```bash
gh workflow run release.yml --ref main
```

With a tag supplied:

```bash
gh workflow run release.yml --ref main -f tag=$ARGUMENTS
```

The dispatch is asynchronous and the run takes a moment to appear. Poll for it, then watch it:

```bash
gh run list --workflow=release.yml -L 1 --json databaseId,status,createdAt,url
gh run watch <databaseId> --exit-status
```

The workflow tags the commit and pushes `<sha>:refs/heads/release`. If it fails, read the log (`gh run view <databaseId> --log-failed`) and report — common causes are a duplicate tag name or a non-fast-forward push, both of which mean nothing was deployed.

---

## Step 6 — Wait for CI on the release commit

Railway holds the deploy until this passes:

```bash
gh run list --workflow=ci.yml --branch release -L 1 --json databaseId,status,conclusion,headSha,url
gh run watch <databaseId> --exit-status
```

Confirm `headSha` matches the commit that was just released (`git rev-parse origin/main` before the push).

If CI fails here, the deploy is skipped and production is untouched — but `release` now points at the bad commit. **Fix forward on `main` and cut another release.** Do not force-push `release` backwards.

---

## Step 7 — Verify the deploy

Railway builds once CI is green. Give it time, then check the healthcheck endpoint:

```bash
curl -sS -o /dev/null -w '%{http_code}\n' https://fractional-jet-production.up.railway.app/up
```

`200` means the new container passed its healthcheck and is serving. Anything else, or a timeout, means the deploy is still building or has failed — point the user at the Railway dashboard for build and deploy logs (`railway logs` needs the app service linked; `railway status` shows what is currently linked).

---

## Step 8 — Report

Tell the user:

- The tag that was cut and the commit it points at
- What shipped (the PR list from Step 2)
- Migration and configuration items that were flagged, and how they were resolved
- The state of the CI run and the healthcheck
- Anything left to do manually

Keep it short. If everything passed, a few lines is enough.
