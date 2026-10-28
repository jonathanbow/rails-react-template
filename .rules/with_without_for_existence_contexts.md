# Use "with" and "without" for Existence Contexts

RSpec context descriptions should use consistent vocabulary. Reserve specific words for specific meanings.

## The Rule

- Use `with` and `without` for presence/absence of something
- Reserve `when` for scenarios, conditions, and state changes

## Examples

```ruby
# Bad - using "when" for existence
context "when foo exists" do
  # ...
end

context "when there is no foo" do
  # ...
end
```

```ruby
# Good - using "with/without" for existence
context "with foo" do
  # ...
end

context "without foo" do
  # ...
end
```

```ruby
# Good - using "when" for scenarios and conditions
context "when the email is changed" do
  # ...
end

context "when the user clicks submit" do
  # ...
end

context "when the API returns an error" do
  # ...
end
```

## The Three Context Words

RSpec (with rubocop-rspec) encourages three prefixes:

| Word      | Use For                      |
| --------- | ---------------------------- |
| `with`    | Something is present         |
| `without` | Something is absent          |
| `when`    | A condition, state, or event |

## Why This Matters

- **Scannability**: Presence checks are extremely common; consistent vocabulary makes them easy to spot
- **Precision**: "when foo" is ambiguous; "with foo" clearly means foo exists
- **Convention**: Team consistency reduces cognitive load when reading tests
