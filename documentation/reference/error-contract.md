# Reference: Error Contract

The public Elixir surface is normalized to:

- `{:ok, value}`
- `:ok` for action calls
- `{:error, reason}`

## Design Rules

- Normal operational failures should not raise.
- Rust panics are caught at the NIF boundary and returned as errors.
- Error reasons are plain terms suitable for matching in callers.

## Example Matches

```elixir
case ExLanceDB.search(table, embedding, limit: 10) do
  {:ok, hits} -> {:ok, hits}
  {:error, :embedding_must_be_numeric} -> {:error, :bad_input}
  {:error, reason} -> {:error, {:search_failed, reason}}
end
```

## Validation Errors

Elixir boundary validations include:

- `:records_must_be_maps`
- `:embedding_must_be_numeric`
- `{:invalid_limit, value}`
- `{:invalid_filter, value}`
- `{:unsupported_index, index_type}`
