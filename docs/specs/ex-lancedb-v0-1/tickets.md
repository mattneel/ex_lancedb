<!-- status: locked -->
# Tickets: ex_lancedb v0.1

## Ticket Style
Detailed tickets selected because this is a greenfield Elixir+NIF implementation with cross-language failure modes.

## Execution Order
- Sequential: T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> T7 -> T8 -> T9
- Parallel groups: none for initial implementation due shared core files and high coupling.

---

### T1: Establish Elixir app skeleton and naming
**Specs**: epic-brief.md, tech-plan.md §File Changes
**Files**: `mix.exs`, `lib/ex_lancedb.ex`, `lib/ex_lance_db/application.ex`
**Touch list**: project config, public API entrypoint, application startup
**Dependencies**: None
**Effort**: Small (1-2 hours)
**Parallel group**: —

**Description**:
Create canonical `ExLanceDB` entrypoint and application module wiring while keeping a compatibility `ExLancedb` facade.

**Acceptance Criteria**:
- [ ] Project compiles with `ExLanceDB` public module.
- [ ] OTP app starts with `ExLanceDB.Application`.
- [ ] Legacy `ExLancedb` module remains callable for compatibility.

**Verification**:
- Commands: `mix test`
- Manual checks: `iex -S mix` load `ExLanceDB`.

**Rollback**:
- Revert commit; no data migration impact.

---

### T2: Add Rustler integration and NIF crate skeleton
**Specs**: tech-plan.md §Design Decisions, §Component Architecture
**Files**: `mix.exs`, `config/config.exs`, `lib/ex_lance_db/nif.ex`, `native/ex_lancedb_nif/Cargo.toml`, `native/ex_lancedb_nif/src/lib.rs`
**Touch list**: dependencies, rustler config, NIF loader, crate bootstrapping
**Dependencies**: T1
**Effort**: Medium (2-4 hours)
**Parallel group**: —

**Description**:
Integrate Rustler and create compilable NIF crate with stubbed functions and Tokio runtime initialization helper.

**Acceptance Criteria**:
- [ ] `mix compile` builds Elixir and Rust NIF.
- [ ] NIF module loads without crashing.
- [ ] Stub calls return normalized `nif_not_loaded` only before compilation failures, otherwise executable.

**Verification**:
- Commands: `mix deps.get`, `mix compile`, `mix test`
- Manual checks: call a trivial NIF function from IEx.

**Rollback**:
- Remove added dependency and `native/` crate files.

---

### T3: Implement schema DSL and metadata extraction
**Specs**: epic-brief.md §Goals, tech-plan.md §Data Model
**Files**: `lib/ex_lance_db/schema.ex`, `lib/ex_lance_db/table.ex`, `test/ex_lancedb_test.exs`
**Touch list**: macro DSL, schema structs, unit tests
**Dependencies**: T2
**Effort**: Medium (2-4 hours)
**Parallel group**: —

**Description**:
Build `use ExLanceDB.Schema` macro with `field/3`, primary field metadata, and vector dimension validation.

**Acceptance Criteria**:
- [ ] Schema modules can define fields and expose metadata through `__schema__/1`.
- [ ] Invalid field declarations raise compile-time or runtime argument errors with clear messages.
- [ ] Vector fields require positive `:dim`.

**Verification**:
- Commands: `mix test test/ex_lancedb_test.exs`

**Rollback**:
- Revert schema module and dependent tests.

---

### T4: Implement connection supervisor and `connect/1`
**Specs**: core-flows.md §Flow 1, tech-plan.md §Component Architecture
**Files**: `lib/ex_lance_db/connection_supervisor.ex`, `lib/ex_lance_db/connection.ex`, `lib/ex_lance_db/error.ex`, `lib/ex_lance_db/nif.ex`, Rust `src/lib.rs`
**Touch list**: OTP ownership, connect NIF binding, error mapping
**Dependencies**: T3
**Effort**: Medium (2-4 hours)
**Parallel group**: —

**Description**:
Implement supervised connection lifecycle and NIF `connect` call to return connection handles.

**Acceptance Criteria**:
- [ ] `ExLanceDB.connect(path)` returns `{:ok, conn}` on valid path.
- [ ] Invalid path returns `{:error, reason}`.
- [ ] Connection processes are supervised under dynamic supervisor.

**Verification**:
- Commands: `mix test`
- Manual checks: inspect supervisor children during runtime.

**Rollback**:
- Revert connection modules and NIF connect implementation.

---

### T5: Implement table lifecycle (`create_table/3`, `open_table/2`)
**Specs**: core-flows.md §Flow 2
**Files**: `lib/ex_lance_db.ex`, `lib/ex_lance_db/connection.ex`, `lib/ex_lance_db/table.ex`, Rust `src/lib.rs`, `src/convert.rs`
**Touch list**: API wrappers, table resource management, schema conversion
**Dependencies**: T4
**Effort**: Large (4-8 hours)
**Parallel group**: —

**Description**:
Wire schema metadata into NIF calls for create/open table operations and return `%ExLanceDB.Table{}` handles.

**Acceptance Criteria**:
- [ ] Table creation from schema succeeds in integration test.
- [ ] Opening existing table succeeds.
- [ ] Schema mismatch/invalid schema returns normalized error.

**Verification**:
- Commands: `mix test test/ex_lance_db_integration_test.exs`

**Rollback**:
- Revert table lifecycle implementations and tests.

---

### T6: Implement batch insert (`insert/2`)
**Specs**: core-flows.md §Flow 3
**Files**: `lib/ex_lance_db.ex`, `lib/ex_lance_db/connection.ex`, Rust `src/lib.rs`, `src/convert.rs`, tests
**Touch list**: map validation, Arrow/record conversion, insert NIF
**Dependencies**: T5
**Effort**: Large (4-8 hours)
**Parallel group**: —

**Description**:
Convert list of Elixir maps to insertable batches in Rust and insert into LanceDB table.

**Acceptance Criteria**:
- [ ] Valid records insert successfully.
- [ ] Missing fields or bad types produce explicit errors.
- [ ] Vector dimension mismatch is detected and reported.

**Verification**:
- Commands: `mix test test/ex_lance_db_integration_test.exs`

**Rollback**:
- Revert insert implementation and tests.

---

### T7: Implement search with optional filter (`search/3`)
**Specs**: core-flows.md §Flow 4
**Files**: `lib/ex_lance_db.ex`, `lib/ex_lance_db/connection.ex`, Rust `src/lib.rs`, `src/convert.rs`, tests
**Touch list**: query options, result conversion, filter handling
**Dependencies**: T6
**Effort**: Large (4-8 hours)
**Parallel group**: —

**Description**:
Implement vector top-k search with optional SQL filter and return scored tuples.

**Acceptance Criteria**:
- [ ] `search/3` returns `{:ok, [{score, map}]}`.
- [ ] `limit` option is enforced.
- [ ] Filter expression narrows results correctly in integration tests.

**Verification**:
- Commands: `mix test test/ex_lance_db_integration_test.exs`

**Rollback**:
- Revert search logic and tests.

---

### T8: Implement index creation (`create_index/3`) and error normalization hardening
**Specs**: core-flows.md §Flow 5, §Flow 6
**Files**: `lib/ex_lance_db.ex`, `lib/ex_lance_db/error.ex`, Rust `src/lib.rs`, `src/error.rs`, tests
**Touch list**: index API, error mapper, panic containment
**Dependencies**: T7
**Effort**: Medium (2-4 hours)
**Parallel group**: —

**Description**:
Add IVF-PQ index creation path and finalize exhaustive error mapping for all public operations.

**Acceptance Criteria**:
- [ ] `create_index(table, :embedding, :ivf_pq)` returns `:ok` on valid table.
- [ ] Unsupported index types are rejected in Elixir before NIF call.
- [ ] NIF errors are always translated into documented reasons.

**Verification**:
- Commands: `mix test`

**Rollback**:
- Revert index API and error mapping updates.

---

### T9: Finalize documentation and end-to-end tests
**Specs**: epic-brief.md §Success Criteria, tech-plan.md §Testing Strategy
**Files**: `README.md`, `test/support/fixture_data.ex`, `test/ex_lance_db_integration_test.exs`
**Touch list**: docs, fixture generation, integration assertions
**Dependencies**: T8
**Effort**: Medium (2-4 hours)
**Parallel group**: —

**Description**:
Write quickstart docs and complete test coverage for v0.1 contract.

**Acceptance Criteria**:
- [ ] README includes setup, schema example, CRUD/search/index examples.
- [ ] Integration tests cover connect/create/open/insert/search/filter/index and error cases.
- [ ] Full test suite passes.

**Verification**:
- Commands: `mix format --check-formatted`, `mix test`

**Rollback**:
- Revert docs/test commits independently from core logic if needed.

---

### T10: Package-facing usage rules documentation set
**Specs**: epic-brief.md §Goals, user direction on first-class docs packaging
**Files**: `usage-rules.md`, `usage-rules/*.md`, `usage_rules.md`, `README.md`
**Touch list**: package-consumer docs, agent docs index/pages
**Dependencies**: T9
**Effort**: Small (1-2 hours)
**Parallel group**: —

**Description**:
Add root-index + topic-pages documentation pattern for package consumers and agent tooling.

**Acceptance Criteria**:
- [ ] Root usage rules index exists and links to topic pages.
- [ ] Topic pages cover quickstart, schema, operations, native build requirements, and error contract.
- [ ] README links to and explains usage rules doc structure.

**Verification**:
- Commands: `mix test`
- Manual checks: verify links in `usage-rules.md` resolve to existing files.

**Rollback**:
- Revert usage rules docs files independently.

## Execution Status

- [x] T1
- [x] T2
- [x] T3
- [x] T4
- [x] T5
- [x] T6
- [x] T7
- [x] T8
- [x] T9
- [x] T10
