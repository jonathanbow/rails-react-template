# No Mutations in Presentation Helpers

Presentation helpers (`lib/` formatting functions, `hooks/` that derive display data) exist to shape data for rendering. They should never trigger a mutation.

## The Rule

`lib/` helpers and derived-state `hooks/` used by page components should be pure:

- Accept data, return formatted/derived data
- No side effects
- No calling `router.post`/`patch`/`put`/`delete`/`visit`, no `useForm().submit()`, no fetch calls

Triggering a mutation (creating, updating, archiving, deleting a record) belongs in the page component's event handler (`onClick`, `onSubmit`), which calls the corresponding Inertia action against a Rails controller — never inside a formatting/derived-data helper.

## Examples

```tsx
// Bad - mutation hidden inside a "helper"
// lib/utils.ts
export function archiveProject(project: Project) {
  router.patch(projectPath(project), { archived: true })
}

// pages/projects/index.tsx
<Button onClick={() => archiveProject(project)}>Archive</Button>
```

```tsx
// Good - mutation trigger stays visible in the component
// pages/projects/index.tsx
<Button onClick={() => router.patch(projectPath(project), { archived: true })}>
  Archive
</Button>
```

## Acceptable Exception

A hook whose entire purpose is to encapsulate a mutation (not to format/derive display data) is a different category and is fine — e.g. a shared `useAutosave` hook wrapping a debounced `router.patch` call. This rule targets helpers whose stated job is formatting/derivation, not hooks that exist specifically to own a mutation.

## Why This Matters

- **Predictability**: reading a page component's event handlers tells you every mutation it can trigger; nothing is hidden inside a formatting helper.
- **Testability**: pure `lib/`/`hooks/` functions can be unit tested with plain inputs/outputs, no request mocking.
- **Consistency with the backend**: mirrors this repo's controller convention (`CLAUDE.md`) — the caller decides when a side effect happens, it isn't buried in a callback.
