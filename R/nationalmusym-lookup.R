#' Create National MUSYM Lookup Snapshot
#'
#' Creates a snapshot of MUKEY:NATIONALMUSYM:AREASYMBOL from Soil Data Access for the current fiscal year, sorted by areasymbol and mukey.
#'
#' @return Data frame. With mukey, nationalmusym, and areasymbol columns.
#' @export
create_nationalmusym_lookup <- function() {
  fy <- fiscal_year_from_date()

  x <- soilDB::SDA_query("~DeclareVarchar(@json,max)~
    ;WITH src (n) AS (SELECT DISTINCT m.mukey, m.nationalmusym, l.areasymbol
    FROM mapunit m
    INNER JOIN legend l ON m.lkey = l.lkey
    ORDER BY l.areasymbol, m.mukey
    FOR JSON AUTO)
    SELECT @json = src.n
    FROM src
    SELECT @json, LEN(@json);")

  res <- jsonlite::fromJSON(x$V1)
  
  # Flatten the nested l structure
  res$areasymbol <- sapply(res$l, function(x) x$areasymbol[1])
  res$l <- NULL

  # Validate against schema
  schema <- jsonlite::fromJSON(system.file("schemas", "nationalmusym-lookup.json", package = "SSURGOsnapshots"), simplifyVector = TRUE)
  validate_snapshot_data(res, schema)

  # Create artifacts directory
  dir.create("artifacts", showWarnings = FALSE)

  # Write to file
  write.csv(res, file.path("artifacts", sprintf("nationalmusym-lookup-FY%s.csv", fy)),
            quote = FALSE, row.names = FALSE)

  # Generate and write metadata
  metadata <- generate_snapshot_metadata("nationalmusym-lookup", fy)
  jsonlite::write_json(metadata, file.path("artifacts", "metadata.json"), pretty = TRUE, auto_unbox = TRUE)

  invisible(res)
}

#' Get National MUSYM Lookup
#'
#' Downloads and loads the national MUSYM lookup for a specified fiscal year from GitHub releases.
#'
#' @param fy Numeric. Fiscal year. Default: current fiscal year.
#' @param repo Character. GitHub repository. Default: `"brownag/SSURGOsnapshots"`.
#' @param force Logical. Force redownload even if cached. Default: `FALSE`.
#' @return Data frame. With mukey, nationalmusym, and areasymbol columns.
#' @export
get_nationalmusym_lookup <- function(fy = NULL, repo = "brownag/SSURGOsnapshots", force = FALSE) {
  if (is.null(fy)) {
    fy <- fiscal_year_from_date()
  }
  download_snapshot_asset("nationalmusym-lookup", fy, repo, force)
}