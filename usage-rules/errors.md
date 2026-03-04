# Error Contract Rules

- Public Elixir API should never raise for normal operational failures.
- Return shapes:
  - success: `{:ok, value}` or `:ok` for action-style calls
  - failure: `{:error, reason}`
- Rust panics must be caught and surfaced as explicit error values.
- Add tests for every new failure mode introduced.
