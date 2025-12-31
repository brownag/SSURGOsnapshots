#' Download Snapshot Asset
#'
#' @param snapshot_id Character. The ID of the snapshot.
#' @param fy Numeric. Fiscal year.
#' @param repo Character. GitHub repository. Default: `"brownag/SSURGOsnapshots"`.
#' @param force Logical. Force redownload even if cached. Default: `FALSE`.
#' @return Data frame. From the downloaded CSV.
#' @export
download_snapshot_asset <- function(snapshot_id, fy, repo = "brownag/SSURGOsnapshots", force = FALSE) {
  cache_dir <- tools::R_user_dir("SSURGOsnapshots", which = "cache")
  dir.create(cache_dir, showWarnings = FALSE, recursive = TRUE)
  cache_file <- file.path(cache_dir, sprintf("%s-FY%s.csv", snapshot_id, fy))
  
  if (!force && file.exists(cache_file)) {
    return(read.csv(cache_file, stringsAsFactors = FALSE))
  }
  
  if (!requireNamespace("gh", quietly = TRUE)) {
    stop("Package 'gh' is required. Install with install.packages('gh')")
  }
  releases <- gh::gh("GET /repos/{repo}/releases", repo = repo)
  tag <- sprintf("FY%s", fy)
  release <- releases[sapply(releases, function(x) x$tag_name == tag)]
  if (length(release) == 0) {
    stop("No release found for ", tag)
  }
  release <- release[[1]]
  asset <- release$assets[sapply(release$assets, function(x) grepl(snapshot_id, x$name))][[1]]
  if (is.null(asset)) {
    stop("No asset found for ", snapshot_id)
  }
  temp <- tempfile(fileext = ".csv")
  on.exit(unlink(temp))
  download.file(asset$browser_download_url, temp)
  data <- read.csv(temp, stringsAsFactors = FALSE)
  write.csv(data, cache_file, row.names = FALSE)
  data
}

.fiscal_year_from_date <- function(
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