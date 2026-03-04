# Cheatsheet: Schema DSL

## Minimal Schema

```elixir
defmodule Mechanics do
  use ExLanceDB.Schema

  field :id, :string, primary: true
  field :name, :string
  field :embedding, :vector, dim: 768
end
```

## Field Options

- `primary: true` marks primary key metadata
- `dim: integer` required for `:vector`

## Supported Types

- `:string`
- `:integer`
- `:float`
- `:boolean`
- `:vector`

## Common Mistakes

- Missing `dim` for vector fields
- Non-positive `dim`
- Unsupported type atoms
