# ex_lancedb Usage Rules

This file is the root index for agent- and contributor-facing implementation rules.

## Read Order

1. [Quickstart](usage-rules/quickstart.md)
2. [Schema DSL](usage-rules/schema.md)
3. [Table Operations](usage-rules/operations.md)
4. [NIF Build Requirements](usage-rules/nif-build.md)
5. [Error Contract](usage-rules/errors.md)
6. [Livebook Example](usage-rules/livebook.md)

## Scope

These rules apply to code changes in `lib/`, `native/`, tests, and user-facing docs.

## Core Principles

- Preserve API shape: `{:ok, value} | {:error, reason}`.
- Keep blocking native work on dirty NIF schedulers.
- Do not expose Arrow or Rust internal types to Elixir callers.
- Prefer additive changes over breaking contract changes in `v0.1`.
