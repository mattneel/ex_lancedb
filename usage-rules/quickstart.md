# Quickstart Rules

- Use `ExLanceDB.connect/1` for all DB entrypoints.
- Define schemas with `use ExLanceDB.Schema` and `field/3`.
- Store vector embeddings in `:vector` fields with explicit `dim`.
- Use `insert/2` for batch map inserts.
- Use `search/3` with `limit:` and optional `filter:`.
- Use `create_index/3` with `:ivf_pq` for vector index creation.
