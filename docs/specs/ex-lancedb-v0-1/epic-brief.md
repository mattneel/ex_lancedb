<!-- status: locked -->
<!-- epic-slug: ex-lancedb-v0-1 -->
# Epic Brief: ex_lancedb v0.1 Embedded Vector Search Client

## Problem
Elixir developers need vector search for RAG and semantic retrieval but current options force either external infrastructure (HTTP sidecars) or poor ANN performance at higher scale (`pgvector` in Postgres). There is no serious native Elixir LanceDB client that provides embedded vector search with an idiomatic API.

## Who's Affected
- Phoenix and Elixir application developers building semantic search and RAG features.
- Teams that want low-ops deployment and do not want to run a separate vector database service.
- Elixir developers without Rust expertise who still need production-grade vector retrieval.

## Goals
- Provide an idiomatic Elixir API over LanceDB via Rustler NIF.
- Support the v0.1 API surface:
  - `connect/1`
  - `create_table/3`, `open_table/2`
  - `insert/2`
  - `search/3` with optional SQL-style filter
  - `create_index/3`
- Ensure stable error behavior: all public calls return `{:ok, value} | {:error, reason}`.
- Keep LanceDB embedded (single process, local files) with no external service requirement.
- Provide a working quickstart and integration tests against real LanceDB data.

## Non-Goals
- ORM behavior (migrations, changesets, associations).
- Relational data modeling replacement.
- Managed embedding generation pipelines.
- Distributed or multi-node LanceDB operation.
- Full-text/BM25, multi-vector columns, time-travel, cloud connections (all deferred).

## Constraints
- Elixir-first consumer experience; no Arrow types leaked into Elixir APIs.
- Blocking IO from LanceDB must never run on normal BEAM schedulers.
- Rust panics must not cross NIF boundary.
- Initial packaging (`v0.1`) can require local Rust toolchain.
- Repository starts from a near-empty scaffold; all core modules must be created.

## Actors

| Actor | Description |
|-------|-------------|
| Host Elixir App | Calls `ExLanceDB` API to manage tables and query vectors |
| ExLanceDB Elixir Layer | Public API, supervision, schema metadata, error normalization |
| Rustler NIF Layer | Boundary for conversions, runtime orchestration, panic containment |
| LanceDB Rust Client | Performs embedded storage, indexing, and vector search |
| Local Filesystem | Stores Lance/LanceDB data files |

## Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Runtime model | Tokio runtime in Rust `OnceLock` + dirty NIF calls | Avoid blocking schedulers and keep async LanceDB internals usable |
| Elixir ownership | Connection process under supervisor | Align with OTP lifecycle and fault boundaries |
| Schema definition | `use ExLanceDB.Schema` macro | Idiomatic Elixir DSL with compile-time validation |
| Error contract | Normalize to `{:ok, _} | {:error, reason}` | Predictable API for callers and better supervision behavior |
| Rustler baseline | `rustler ~> 0.37.3` | Matches supplied Rustler reference and current stable usage |

## Success Criteria
- A Phoenix app can embed `ex_lancedb` without sidecars.
- A test fixture can ingest at least 100k vectors in batch mode.
- Filtered top-k similarity query returns top-10 scored records with deterministic shape `[{score, map}]`.
- Public API paths never crash BEAM due to uncaught Rust panics.
- ExUnit integration suite passes on local fixture-backed LanceDB operations.

## Out of Scope (v0.1)
- BM25/full-text hybrid search.
- Multi-vector columns.
- Time travel/versioned queries.
- LanceDB cloud remote connectivity.
- Streaming inserts.
- `rustler_precompiled` binary distribution.

## Definitions
- Embedded DB: Database runs in-process and persists to local disk, no separate service.
- Vector search: Similarity retrieval against a dense embedding column.
- Hybrid search (v0.1 interpretation): Vector search plus SQL-style metadata filter.
- Dirty NIF: NIF scheduled on dirty scheduler pool to isolate blocking work.

## Assumptions and Unknowns

| Item | Type | Validation | Owner |
|------|------|------------|-------|
| `ExLanceDB` naming will replace scaffold `ExLancedb` | Assumption | Enforce module rename in initial tickets | Implementation |
| LanceDB Rust API supports required operations in one crate version | Unknown | Lock crate versions and pass integration tests | Implementation |
| SQL-style filter strings are accepted by LanceDB search path | Assumption | Verify in integration tests with known fixtures | Implementation |
| IVF-PQ index creation API is available in chosen crate version | Unknown | Compile and run index integration test | Implementation |

## Kill Criteria / Stop Conditions
- Chosen LanceDB crate version lacks required v0.1 operations without major workaround complexity.
- NIF safety constraints (panic isolation + dirty scheduler + resource safety) cannot be satisfied reliably.
- Integration tests show unacceptable stability under repeated connect/insert/search cycles.
