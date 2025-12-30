#' Validate Snapshot Data Against Schema
#'
#' @param data Data frame. The data frame to validate.
#' @param schema List. The schema list defining expected structure.
#' @return Logical. Invisible TRUE if validation passes.
#' @export
validate_snapshot_data <- function(data, schema) {
  expected_cols <- schema$data_structure$columns$name
  if (ncol(data) != length(expected_cols)) {
    stop("Column count mismatch: expected ", length(expected_cols), ", got ", ncol(data))
  }
  if (!all(names(data) == expected_cols)) {
    stop("Column names mismatch: expected ", paste(expected_cols, collapse = ", "), ", got ", paste(names(data), collapse = ", "))
  }
  invisible(TRUE)
}

#' Generate Draft Schema
#'
#' @param data Data frame. The data frame to generate schema from.
#' @param snapshot_id Character. The ID of the snapshot.
#' @param fy Numeric. Fiscal year.
#' @return List. Invisible schema list written to file.
#' @export
generate_draft_schema <- function(data, snapshot_id, fy) {
  # Generate a draft schema from the data frame
  columns <- lapply(names(data), function(col) {
    list(name = col, type = typeof(data[[col]]))
  })
  schema <- list(
    snapshot_id = snapshot_id,
    fiscal_year = fy,
    data_structure = list(
      columns = columns
    ),
    source = "USDA Soil Data Access",
    file_naming = paste0(snapshot_id, "-FY{year}.csv")
  )
  jsonlite::write_json(schema, paste0("inst/schemas/", snapshot_id, ".json"), pretty = TRUE, auto_unbox = TRUE)
  invisible(schema)
}

#' Generate Snapshot Metadata
#'
#' @param snapshot_id Character. The ID of the snapshot.
#' @param fy Numeric. Fiscal year.
#' @return List. Metadata including snapshot schema, fiscal year, file name, and generation timestamp.
#' @export
generate_snapshot_metadata <- function(snapshot_id, fy) {
  schema_file <- system.file("schemas", paste0(snapshot_id, ".json"), package = "SSURGOsnapshots")
  if (schema_file == "") {
    stop("Schema not found for ", snapshot_id)
  }
  schema <- jsonlite::fromJSON(schema_file, simplifyVector = TRUE)

  # Generate test block
  cat("test_that(\"", snapshot_id, " snapshot conforms to schema\", {\n", sep = "")
  cat("  # Load schema\n")
  cat("  schema <- jsonlite::fromJSON(system.file(\"schemas\", \"", snapshot_id, ".json\", package = \"SSURGOsnapshots\"))\n", sep = "")
  cat("  # Load data (adjust path as needed)\n")
  cat("  data <- read.csv(\"artifacts/", sub("\\{year\\}", fy, schema$file_naming), "\")\n", sep = "")
  cat("  # Check structure\n")
  cat("  expect_equal(ncol(data), nrow(schema$data_structure$columns))\n")
  cat("  expect_equal(names(data), schema$data_structure$columns$name)\n")
  cat("})\n\n")

  # Return metadata
  list(
    snapshot = schema,
    fiscal_year = fy,
    file_name = sub("\\{year\\}", fy, schema$file_naming),
    generated_at = Sys.time()
  )
}