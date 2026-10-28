# Test Context Setup Should Be Self-Contained

Each test context should define its own setup, not rely on inherited state from parent contexts.

## The Rule

Define `let` blocks within the context that describes and uses them. Don't cascade test data from outer contexts.

## Examples

```ruby
# Bad - setup cascaded from above
let(:foo) { Foo.new }

context "with foo" do
  it "does something" do
    expect(foo).to be_valid
  end
end

context "with invalid foo" do
  it "fails validation" do
    foo.name = nil
    expect(foo).not_to be_valid
  end
end
```

```ruby
# Good - each context owns its setup
context "with valid foo" do
  let(:foo) { Foo.new(name: "Valid") }

  it "passes validation" do
    expect(foo).to be_valid
  end
end

context "with invalid foo" do
  let(:foo) { Foo.new(name: nil) }

  it "fails validation" do
    expect(foo).not_to be_valid
  end
end
```

## Why This Matters

- **Readability**: Each context is self-documenting; you don't need to scroll up to understand the test
- **Maintainability**: Changes to one context don't accidentally break others
- **Flexibility**: Contexts can be reorganized, extracted, or deleted independently

## Performance Note

There's no performance cost to this approach. RSpec lazily evaluates `let` blocks, and each example gets fresh instances regardless of where the `let` is defined.
