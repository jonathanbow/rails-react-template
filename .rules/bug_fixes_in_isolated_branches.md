# Bug Fixes Must Be in Isolated Branches

Every bug fix deserves its own branch and PR, regardless of when you discover it.

## The Rule

Never fix a bug as part of a feature branch, even if you encounter it while working on that feature. Create a separate branch specifically for the bug fix.

## Why This Matters

1. **Independent release timing**: Bug fixes often need to ship faster than features
2. **Easier rollback**: If a fix causes issues, it can be reverted without affecting unrelated work
3. **Clearer history**: Git history shows exactly what changed to fix a specific bug
4. **Better review**: Reviewers can evaluate the fix on its own merits
5. **Accurate tracking**: Bug fixes can be properly linked to issues and release notes

## Workflow

When you discover a bug while working on a feature:

1. Note the bug (create an issue if needed)
2. Commit or stash your current work
3. Create a new branch from main for the bug fix
4. Fix, test, and submit PR for the bug fix
5. Return to your feature branch
6. Rebase if needed once the fix is merged

## Common Objections

**"It's a one-line fix"**
One-line fixes can still have outsized impact. Keep them isolated.

**"I'm already in the right file"**
Convenience isn't a reason to compromise process.

**"It'll be merged with my feature anyway"**
Maybe, but it should be evaluated and potentially released independently.
