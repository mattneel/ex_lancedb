# Schema Rules

- Supported field types in `v0.1`:
  - `:string`
  - `:integer`
  - `:float`
  - `:boolean`
  - `:vector`
- `:vector` fields must declare `dim: positive_integer`.
- `primary: true` is metadata for callers; uniqueness constraints are not yet enforced automatically.
- Keep schema modules focused on table field definitions only.
