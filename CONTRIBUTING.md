# Contributing

The `SSURGOsnapshots` package provides automated monthly snapshots of SSURGO and related soil data from USDA sources, packaged as an R library for easy access and reproducibility. Snapshots are generated via GitHub Actions, validated against JSON schemas, and released as artifacts.

The package structure separates snapshot-specific functions (one per file in `R/`) from shared utilities in `R/SSURGOsnapshots-*.R`, promoting FAIR principles (Findable, Accessible, Interoperable, Reusable) and ensuring reproducibility through automated validation and modular design.

A Makefile is provided for common development tasks such as building, checking, testing, and documenting the package.

## Adding a New Snapshot

1. Choose a descriptive name for the snapshot, e.g., "soil_properties" for soil properties data. Use lowercase with underscores for readability.
2. Create the data snapshot by writing a `create_[name]_snapshot()` function in `R/` (e.g., `create_soil_properties_snapshot()`) that queries the data, validates it against a schema, and writes artifacts to `artifacts/[name]-lookup-FY{fy}.csv` (e.g., `soil-properties-lookup-FY2026.csv`).
3. Use `generate_draft_schema(data, "[name]-lookup", fy)` to automatically generate a draft JSON schema in `inst/schemas/` based on the data structure.
4. Refine the generated schema as needed (e.g., adjust types or add descriptions).
5. Add a `get_[name]_snapshot()` function in `R/` (e.g., `get_soil_properties_snapshot()`) that uses `download_snapshot_asset("[name]-lookup", fy, repo)` for downloading from GitHub releases.
6. Run `generate_snapshot_metadata("[name]-lookup", fy)` to generate a test block for validation.
7. Add the generated test block to `tests/testthat/test-snapshot-schema.R`.
8. Ensure `validate_snapshot_data()` is called in the create function to check data against the schema.
9. Update the GitHub Actions workflow if needed (it automatically runs all `create_*` functions), and test locally.

All functions are exported for interactive testing and validation.