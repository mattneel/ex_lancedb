# How To: Run Filtered Vector Search

Use `ExLanceDB.search/3` to combine nearest-neighbor retrieval with SQL-style filtering.

## Input Contract

- `embedding`: list of numeric values
- `limit`: positive integer (default `10`)
- `filter`: optional SQL predicate string

## Example

```elixir
{:ok, results} =
  ExLanceDB.search(table, embedding,
    limit: 10,
    filter: "effect_category = 'damage' AND source_game != 'yugioh'"
  )
```

## Return Type

```elixir
{:ok, [{score :: float(), record :: map()}]}
```

## Common Errors

- `{:error, :embedding_must_be_numeric}`
- `{:error, {:invalid_limit, value}}`
- `{:error, {:invalid_filter, value}}`

## Operational Advice

- Create `:ivf_pq` index after initial bulk ingestion.
- Keep vector dimensions consistent with schema declaration.
- Keep filters explicit and validated at call boundaries.
