# No Inline Computation in Page Components

Page components (`app/javascript/pages/**/*.tsx`) should render props, not derive them. Formatting, derived state, and conditional presentation belong in `lib/`, `hooks/`, or a dedicated component.

## The Rule

Don't compute, format, or derive display values directly inside a page component's JSX. Delegate:

- **Formatting** (dates, currency, pluralization) → a helper in `lib/`
- **Derived state** (booleans, computed fields from props) → a hook in `hooks/`, or a named `const` computed once near the top of the component — not inline in the JSX itself
- **Conditional presentation** (status badges, ternaries in markup) → a dedicated component

## Examples

```tsx
// Bad - formatting and status branching inline in JSX
export default function Show({ invoice }: Props) {
  return (
    <div>
      <p>
        {new Date(invoice.due_at).toLocaleString("en-GB", {
          dateStyle: "medium",
          timeStyle: "short",
        })}
      </p>
      {invoice.status === "overdue" ? (
        <Badge variant="destructive">Overdue</Badge>
      ) : (
        <Badge>{invoice.status}</Badge>
      )}
    </div>
  );
}
```

```tsx
// Good - formatting and status branching delegated
export default function Show({ invoice }: Props) {
  return (
    <div>
      <p>{formatDueDate(invoice.due_at)}</p>
      <InvoiceStatusBadge status={invoice.status} />
    </div>
  );
}
```

`formatDueDate` lives in `lib/utils.ts`; `InvoiceStatusBadge` is a dedicated component. Neither the formatting logic nor the status branching lives in the page component itself.

## Existing examples in this repo

- `use-initials.tsx` (`app/javascript/hooks`) derives display initials from a name instead of computing them inside a component.
- `cn` and other helpers in `app/javascript/lib/utils.ts` are the home for shared formatting.

## Acceptable Exceptions

- Trivial nullish fallbacks (`user.name ?? "—"`) don't need extracting.
- A simple, named derived value computed once above the `return` (e.g. `const isCurrentSession = session.id === auth.session.id`) is fine — this rule targets logic embedded directly in JSX, not a clearly-named value referenced from it.

## Why This Matters

- **Testability**: logic in `lib/`/`hooks/` can be exercised without rendering a page.
- **Consistency**: one date/currency/status format used everywhere, not reinvented per page.
- **Readability**: page components stay focused on layout and data flow, not formatting rules.
