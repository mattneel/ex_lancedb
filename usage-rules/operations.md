# Table Operations Rules

## Create/Open

- `create_table/3` requires a connection, table name, and schema module.
- `open_table/2` opens an existing table by name.

## Insert

- `insert/2` accepts list of maps.
- Field type mismatches and vector dimension mismatches return `{:error, reason}`.

## Search

- `search/3` requires numeric embedding list.
- `limit:` must be a positive integer.
- `filter:` must be SQL filter string accepted by LanceDB.
- Result shape is `[{score, map}]`.

## Indexing

- `create_index/3` currently supports only `:ivf_pq`.
