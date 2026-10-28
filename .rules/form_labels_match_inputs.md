# Form Labels Must Match Their Inputs

Every form label must be properly associated with its corresponding input element.

## The Rule

The `htmlFor` prop on a `Label`/`FieldLabel` must match the `id` prop of its associated `Input`, `Select`, `Textarea`, or `Checkbox`.

## Examples

```tsx
// Bad - label doesn't match input
<FieldLabel htmlFor="user_name">Name</FieldLabel>
<Input id="name" name="name" />
```

```tsx
// Good - label matches input
<FieldLabel htmlFor="name">Name</FieldLabel>
<Input id="name" name="name" />
```

Pair shadcn's `FieldLabel` (`components/ui/field.tsx`) or `Label` (`components/ui/label.tsx`) with `Input` (`components/ui/input.tsx`) via a matching `htmlFor`/`id` pair, never a bare `<label>`/`<input>`. The settings forms (e.g. `pages/settings/profiles/show.tsx`) are the reference.

## Why This Matters

- **Accessibility**: screen readers rely on label associations to describe form fields
- **Usability**: clicking a label focuses or toggles its associated input
- **Compliance**: proper labeling is required for WCAG accessibility standards
- **Testing**: automated accessibility tools flag mismatched labels as errors

## Verification

Since there's no automated accessibility test suite in this repo (the repo has no frontend tests), verify by hand in the browser: click each label and confirm it focuses/toggles the right field. Browser devtools' accessibility tree, or an extension like axe DevTools, will also flag mismatches without writing a test.
