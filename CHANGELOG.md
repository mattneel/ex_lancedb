# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- ExDoc information architecture with tutorials, how-to, reference, and cheatsheet guides.
- Contributor workflow documents (`CONTRIBUTING.md`) and issue templates.
- CI quality and security workflow scaffolding (`dependabot`, dependency review, scorecards).

## [0.1.0] - 2026-03-04

### Added
- OTP-supervised embedded LanceDB connection lifecycle.
- Schema DSL (`ExLanceDB.Schema`) with vector dimension validation.
- Batch insert from Elixir maps into LanceDB via Rustler NIF.
- Vector search with optional SQL filter and scored result tuples.
- IVF-PQ index creation API.
- Rustler precompiled release workflow for Linux/macOS (x86_64 + aarch64).
- Livebook quickstart and integration tests against real LanceDB data.

[Unreleased]: https://github.com/mattneel/ex_lancedb/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/mattneel/ex_lancedb/releases/tag/v0.1.0
