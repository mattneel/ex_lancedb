# Release Helpers

## sync_checksum_from_release.sh

Syncs `checksum-Elixir.ExLanceDB.Nif.exs` from a tagged GitHub release.

Example:

```bash
scripts/release/sync_checksum_from_release.sh --tag v0.1.0
```

Options:

- `--repo owner/repo` (default inferred from `origin`)
- `--workflow precompiled_nifs.yml` (default)
- `--timeout 1800` seconds (default)
- `--no-commit` download only

Typical flow:

1. `git tag vX.Y.Z`
2. `git push origin master`
3. `git push origin vX.Y.Z`
4. `scripts/release/sync_checksum_from_release.sh --tag vX.Y.Z`
5. review + push checksum commit
6. publish Hex package (manual, intentionally separate)
