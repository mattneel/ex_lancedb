# Reference: Architecture

`ex_lancedb` uses a thin Elixir API layer with Rust native execution through Rustler.

```mermaid
flowchart TD
  A[Elixir Application] --> B[ExLanceDB.ConnectionSupervisor]
  B --> C[ExLanceDB.Connection GenServer]
  C --> D[Rustler NIF DirtyIo functions]
  D --> E[lancedb Rust client]
  E --> F[Lance files on disk]
```

## Runtime Notes

- Connection and table handles are Rustler resources.
- Blocking LanceDB calls run on dirty schedulers.
- Tokio runtime is initialized once in the NIF layer.
- Arrow conversion is encapsulated in Rust, not exposed to Elixir callers.
