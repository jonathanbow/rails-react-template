# Stacked Pull Requests

A stack is a chain of branches where each one targets the branch below it instead of `main`. Reviewers see only the diff for their layer, so a large change becomes several PRs a person can actually hold in their head.

Use GitHub's native stacks via the official `gh stack` extension (public preview since 2026-07-30):

```bash
gh extension install github/gh-stack
```

## The Rule

Build the stack bottom-up, keep it in sync from the bottom up, and never hand-merge a generated file.

- **Each layer branches off the one below it** — `gh stack init` for the bottom layer, `gh stack add` for every layer after it. Never `git checkout -b` off `main` for a layer that depends on unmerged work.
- **After any change to a lower layer, run `gh stack sync`.** That includes review fixes, a rebase onto `main`, and a lower PR being merged. It cascade-rebases each branch onto its updated parent and force-pushes atomically with `--force-with-lease --atomic`.
- **Never `git push --force` a stack branch by hand.** `gh stack sync` and `gh stack rebase` own the force-push; a manual one races the other layers.
- **Each layer must be green on its own.** `bin/ci` before submitting a layer, not just at the top of the stack.

## Regenerate, never hand-merge

Three files in this repo are generated, and every layer that touches them will conflict on rebase. Resolving the hunks by hand produces a file that matches neither layer:

| File | Resolution |
|------|------------|
| `db/schema.rb` | Take the parent's version, then `bin/rails db:migrate` |
| `app/javascript/routes/**`, `app/javascript/types/**` (typelizer) | Take the parent's version, then `bin/rails typelizer:generate:refresh` |
| `Gemfile.lock` | Take the parent's version, then `bundle install` |

Hand-written files that several layers touch (`app/javascript/components/app-sidebar.tsx`, `config/routes.rb`) conflict normally and are resolved normally — but prefer to avoid the collision in the first place by having one layer own a given line. When two layers would edit the same line of `app-sidebar.tsx`, let the later one make the change and leave the earlier one out of it entirely.

## Workflow

```bash
gh stack init feature/layer-one          # bottom layer, branches off main
# ...implement, commit per step, bin/ci...
gh stack submit --auto                   # pushes and opens a draft PR

gh stack add feature/layer-two           # branches off layer one
# ...implement, commit per step, bin/ci...
gh stack submit --auto

gh stack view                            # see the whole chain
gh stack up / down / switch              # move between layers
gh stack sync                            # after anything below you changed
gh stack merge                           # atomic merge up to a chosen PR
```

`gh stack submit` opens an interactive editor in a terminal, which is why `--auto` is used in scripted and agent contexts. `--auto` generates PR titles and creates PRs as **drafts**; fix the title and body afterwards with `gh pr edit`, following `.rules/commit_messages.md`, and mark a layer ready with `gh stack submit --open` once it has been verified.

`gh stack merge` is all-or-nothing for every layer up to the PR you choose (`--squash`, `--rebase`, `--merge`). Bypassing merge requirements is not supported for stacks. You can also merge just the bottom PR through the web UI — the layers above retarget and rebase themselves, but run `gh stack sync` afterwards to bring your local copies in line.

## Why This Matters

1. **Reviewable units**: a reviewer approves one layer without holding three others in their head
2. **Parallel review**: layer 3 can be read while layer 1 is still being argued about
3. **CI per layer**: `.github/workflows/ci.yml` triggers on `pull_request` with no branch filter, so every layer gets a full CI run against the layer below it — a broken foundation surfaces on its own PR, not four PRs later
4. **Cheap reordering**: `gh stack modify` restructures the chain instead of a manual rebase marathon

## Common Objections

**"I'll just rebase manually, I know git."** The cascade is the problem, not any single rebase — four layers means four rebases in the right order, plus four force-pushes that must not race. `gh stack sync` does exactly that, atomically, and restores every branch if a conflict is hit mid-way.

**"The bug I found is one line, I'll fix it in this layer."** No — `.rules/bug_fixes_in_isolated_branches.md` still applies inside a stack, and applies harder. A fix buried in layer 3 can't ship until layers 1 and 2 are approved.

**"Can't I just open one big PR and split it later?"** Splitting after the fact means rewriting history you've already asked someone to review. Start stacked, or don't.
