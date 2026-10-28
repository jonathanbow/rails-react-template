# Method Length

Enforced via `Metrics/MethodLength` in `.rubocop.yml` (`Max: 5`), with multi-line arrays and hashes counted as one line. `db/migrate/**` is excluded, since migration `change` methods are declarative schema DSL rather than hand-written logic.

`Max: 5` is the enforced value, not an aspiration. Write new methods to fit it, favoring early-return guard clauses over `if/else` blocks for the common save/update/destroy-and-redirect shape:

```ruby
def update
  return redirect_to settings_profile_path, notice: "Saved" if @user.update(user_params)

  redirect_to settings_profile_path, inertia: { errors: @user.errors }
end
```

Don't add `rubocop:disable Metrics/MethodLength` suppressions. If a method won't fit, extract a well-named private method instead.
