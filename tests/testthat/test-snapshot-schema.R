test_that("nationalmusym_lookup snapshot conforms to schema", {
  # Skip if artifacts not present (e.g., in local testing)
  test_file <- "artifacts/nationalmusym-lookup-FY2026.csv"
  if (!file.exists(test_file)) {
    skip("Snapshot file not found, run create_nationalmusym_lookup() first")
  }
  # Load schema
  schema <- jsonlite::fromJSON(system.file("schemas", "nationalmusym-lookup.json", package = "SSURGOsnapshots"))
  # Load data
  data <- read.csv(test_file)
  # Check structure
  expect_equal(ncol(data), length(schema$data_structure$columns))
  expect_equal(names(data), sapply(schema$data_structure$columns, `[[`, "name"))
})