# Reference: Public API

## Functions

- `ExLanceDB.connect/1`
- `ExLanceDB.create_table/3`
- `ExLanceDB.open_table/2`
- `ExLanceDB.insert/2`
- `ExLanceDB.search/3`
- `ExLanceDB.create_index/3`

## Schema DSL

`use ExLanceDB.Schema` with field declarations:

```elixir
field :id, :string, primary: true
field :embedding, :vector, dim: 768
```

Supported types:

- `:string`
- `:integer`
- `:float`
- `:boolean`
- `:vector`

## Result Shapes

- action-style success: `:ok`
- query-style success: `{:ok, value}`
- failure: `{:error, reason}`

Search returns:

```elixir
{:ok, [{score :: float(), record :: map()}]}
```

## Compatibility Note

`ExLancedb` remains as a deprecated compatibility facade over `ExLanceDB`.

## Mix Tasks

- `mix ex_lancedb.new_schema Module.Name [--table name --dim 768 --primary id]`
- `mix ex_lancedb.gen.livebook [--path livebooks/demo.livemd --dim 4]`
