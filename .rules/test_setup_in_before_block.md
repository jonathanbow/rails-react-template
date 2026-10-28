# Test Setup Should Be in a Before Block

Separate test setup from test verification. The `it` block should focus on assertions.

## The Rule

Use `let` for data definitions and `before` for actions/mutations. The `it` block should contain only expectations.

## Examples

```ruby
# Bad - setup mixed with verification
it "verifies the user" do
  user = create(:user, verified: false)
  user.update!(verified: true)

  expect(user).to be_verified
end
```

```ruby
# Good - setup separated from verification
let(:user) { create(:user, verified: false) }

before do
  user.update!(verified: true)
end

it "verifies the user" do
  expect(user).to be_verified
end
```

## When to Use Each

| Construct | Purpose                                          |
| --------- | ------------------------------------------------ |
| `let`     | Define data and objects                          |
| `let!`    | Define data that must exist before the test runs |
| `before`  | Perform actions, mutations, or setup state       |
| `it`      | Assert expectations only                         |

## Complex Example

```ruby
describe "changing the email" do
  let(:user) { create(:user) }

  before do
    user.update!(email: "changed@example.com")
  end

  it "marks the user unverified" do
    expect(user).not_to be_verified
  end

  it "stores the new email" do
    expect(user.email).to eq("changed@example.com")
  end
end
```

Build the base record with a FactoryBot factory (`build(:user)` or `create(:user)`, from `spec/factories`) in a `let`, and use `before` only for the action under test.

## Why This Matters

- **Readability**: Test intent is immediately clear
- **DRY**: Setup can be shared across multiple `it` blocks
- **Debugging**: Failures point to specific expectations, not setup code
