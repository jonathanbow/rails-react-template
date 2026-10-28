# Avoid Law of Demeter Violations

The Law of Demeter (LoD) states that an object should only talk to its immediate collaborators. Violations create tight coupling and fragile code.

## The Rule

Don't chain method calls through multiple objects. Each unit of code should have limited knowledge about other units.

Reference: [Thoughtbot's Ruby Science - Law of Demeter](https://thoughtbot.com/ruby-science/law-of-demeter.html)

## Examples

```ruby
# Bad - reaching through multiple objects
user.projects.invoices.paid.created_between(start_date, end_date)
```

```ruby
# Good - encapsulate the query in a single method
user.paid_invoices_created_between(start_date, end_date)
```

## Acceptable Exceptions

Presence checks on immediate collaborators are acceptable:

```ruby
# Acceptable
foo.bars.any?
foo.bars.empty?

# Rails may also provide these as:
foo.bars?
```

## Why Scopes Violate LoD

Rails encourages scope chaining, but this creates brittleness:

```ruby
# Fragile - knowledge of project, invoice, and status structures
user.projects.invoices.paid.created_between(start_date, end_date)
```

If any intermediate object changes its interface, every call site breaks. Encapsulating this logic in a single method isolates the change impact.

## Benefits

- Reduced coupling between objects
- Fewer far-reaching side effects from changes
- Easier refactoring
- More readable code at call sites
