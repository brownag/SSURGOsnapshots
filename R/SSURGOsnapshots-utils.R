#' Download Snapshot Asset
#'
#' @param snapshot_id Character. The ID of the snapshot.
#' @param fy Numeric. Fiscal year.
#' @param repo Character. GitHub repository. Default: `"brownag/SSURGOsnapshots"`.
#' @param force Logical. Force redownload even if cached. Default: `FALSE`.
#' @return Data frame. From the downloaded CSV.
#' @importFrom utils unzip
#' @export
download_snapshot_asset <- function(snapshot_id, fy, repo = "brownag/SSURGOsnapshots", force = FALSE) {
  if (!requireNamespace("gh", quietly = TRUE)) {
    stop("Package 'gh' is required. Install with install.packages('gh')")
  }
  
  # Cache directory
  cache_dir <- file.path(tools::R_user_dir("SSURGOsnapshots", "cache"), sprintf("FY%s", fy))
  if (!dir.exists(cache_dir)) {
    dir.create(cache_dir, recursive = TRUE)
  }
  
  csv_file <- file.path(cache_dir, sprintf("%s-FY%s.csv", snapshot_id, fy))
  metadata_file <- file.path(cache_dir, "metadata.json")
  
  # Get release info
  releases <- gh::gh("GET /repos/{repo}/releases", repo = repo)
  tag <- sprintf("FY%s", fy)
  release <- releases[sapply(releases, function(x) x$tag_name == tag)]
  if (length(release) == 0) {
    stop("No release found for ", tag)
  }
  release <- release[[1]]
  current_commit <- release$target_commitish
  
  # Check if we need to redownload
  needs_download <- force || !file.exists(csv_file) || !file.exists(metadata_file)
  if (!needs_download && file.exists(metadata_file)) {
    cached_metadata <- jsonlite::fromJSON(metadata_file)
    needs_download <- cached_metadata$commit != current_commit
  }
  
  if (needs_download) {
    # Download and extract
    asset <- release$assets[sapply(release$assets, function(x) grepl("ssurgo-snapshot", x$name))][[1]]
    if (is.null(asset)) {
      stop("No asset found for snapshot")
    }
    temp_zip <- tempfile(fileext = ".zip")
    download.file(asset$browser_download_url, temp_zip)
    
    # Clear cache if force or commit changed
    if (force || (exists("cached_metadata") && !is.null(cached_metadata) && cached_metadata$commit != current_commit)) {
      unlink(list.files(cache_dir, full.names = TRUE), recursive = TRUE)
    }
    
    # Extract to cache dir
    unzip(temp_zip, exdir = cache_dir)
    
    # Save metadata
    metadata <- list(commit = current_commit, downloaded_at = Sys.time())
    jsonlite::write_json(metadata, metadata_file, auto_unbox = TRUE)
    
    # Clean up
    unlink(temp_zip)
  }
  
  # Read the CSV
  read.csv(csv_file, stringsAsFactors = FALSE)
}

#' Fiscal Year from Date
#'
#' @param current_date Date. The date to calculate fiscal year for. Default: `Sys.Date()`.
#' @param fy_start_date Character. The start date of fiscal year in MM-DD format. Default: `"2000-10-01"`.
#' @return Numeric. The fiscal year.
#' @export
fiscal_year_from_date <- function(
    current_date = Sys.Date(), 
    fy_start_date = "2000-10-01"
) {
  current_date <- as.Date(current_date)
  d0 <- as.Date(fy_start_date)
  fy <- as.numeric(format(current_date, "%Y"))
  
  if (format(current_date, "%m%d") >= format(d0, "%m%d")) {
    fy <- fy + 1
  }
  fy
}