# Commit message format

Match the existing `git log`: a short summary line in the imperative mood, capitalized, with no type prefix and no trailing period.

```
<Summary>
```

Examples (from this repo's history):

```
Add Claude Code commands
Rewrite README for new developers
Switch database from SQLite to PostgreSQL
Replace app logo with lucide Globe icon
```

- Start with a verb: `Add`, `Fix`, `Remove`, `Rename`, `Replace`, `Switch`, `Rewrite`, `Document`.
- Describe what the change does, not how you got there (`Fix session lookup for expired cookies`, not `Fixed bug`).
- Keep the summary under ~72 characters.
- Add a body only when the change needs explanation beyond the summary. Separate it from the summary with a blank line and explain why, not what.
- Each commit should be atomic and leave `bin/ci` green.
