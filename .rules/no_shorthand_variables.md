# Don't Use Shorthand Variables

Variable names should be descriptive and complete. Abbreviations save keystrokes but cost readability.

## The Rule

Use full, descriptive variable names. Avoid abbreviations, acronyms, and shortened forms.

## Examples

```ruby
# Bad
inv = Invoice.find(1)
proj = Project.new
usr = current_user
addr = customer.address
```

```ruby
# Good
invoice = Invoice.find(1)
project = Project.new
user = current_user
address = customer.address
```

## Common Violations

| Avoid       | Use Instead                       |
| ----------- | --------------------------------- |
| `inv`       | `invoice`                         |
| `proj`      | `project`                         |
| `usr` / `u` | `user`                            |
| `addr`      | `address`                         |
| `msg`       | `message`                         |
| `btn`       | `button`                          |
| `idx` / `i` | `index` (or a meaningful name)    |
| `tmp`       | describe what it actually holds   |
| `val`       | describe what value it represents |

## Why This Matters

- Code is read far more often than it's written
- New team members shouldn't need a decoder ring
- Autocomplete makes typing full names nearly effortless
- Abbreviated names often have multiple possible meanings

## Exceptions

Well-established conventions in specific contexts are acceptable:

- `i`, `j` for simple loop indices (though named iterators are often clearer)
- `e` for exception in rescue blocks
- `id` (this is the standard term, not an abbreviation)
