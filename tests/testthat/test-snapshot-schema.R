test_that("validate_snapshot_data works", {
  # Valid data
  schema <- list(data_structure = list(columns = data.frame(
    name = c("col1", "col2"),
    type = c("integer", "character")
  )))
  data <- data.frame(col1 = 1:3, col2 = c("a", "b", "c"))
  expect_silent(validate_snapshot_data(data, schema))
  
  # Mismatch column count
  bad_data <- data.frame(col1 = 1:3)
  expect_error(validate_snapshot_data(bad_data, schema), "Column count mismatch")
  
  # Mismatch column names
  bad_data <- data.frame(col1 = 1:3, col3 = c("a", "b", "c"))
  expect_error(validate_snapshot_data(bad_data, schema), "Column names mismatch")
})

test_that("generate_draft_schema works", {
  data <- data.frame(col1 = 1:3, col2 = c("a", "b", "c"))
  
  # Mock the write to avoid file system issues
  temp_file <- tempfile(fileext = ".json")
  mockery::stub(generate_draft_schema, "jsonlite::write_json", function(x, path, ...) {
    jsonlite::write_json(x, temp_file, ...)
  })
  
  schema <- generate_draft_schema(data, "test", 2026)
  
  expect_equal(schema$snapshot_id, "test")
  expect_equal(schema$fiscal_year, 2026)
  expect_equal(length(schema$data_structure$columns), 2)
  expect_equal(schema$data_structure$columns[[1]]$name, "col1")
  expect_equal(schema$data_structure$columns[[1]]$type, "integer")
})

test_that("generate_snapshot_metadata works", {
  # Create a temp schema file
  temp_schema <- tempfile(fileext = ".json")
  schema_content <- list(
    snapshot_id = "test",
    file_naming = "test-FY{year}.csv",
    data_structure = list(columns = data.frame(name = "col1"))
  )
  jsonlite::write_json(schema_content, temp_schema)
  on.exit(unlink(temp_schema))
  
  mockery::stub(generate_snapshot_metadata, "system.file", temp_schema)
  
  metadata <- generate_snapshot_metadata("test", 2026)
  
  expect_equal(metadata$snapshot, schema_content)
  expect_equal(metadata$fiscal_year, 2026)
  expect_equal(metadata$file_name, "test-FY2026.csv")
  expect_true(inherits(metadata$generated_at, "POSIXct"))
})

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