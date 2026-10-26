## What and why

## Checks

- [ ] `swift test` passes on macOS (and the iPhone simulator for library changes)
- [ ] `scripts/generate-workflows.sh --check` passes (run it without `--check` after generator changes)
- [ ] `mobileci lint` and `actionlint` report nothing for `.github/workflows` and `Templates`
- [ ] New rules or options are documented in the DocC catalog and listed in `CHANGELOG.md`
