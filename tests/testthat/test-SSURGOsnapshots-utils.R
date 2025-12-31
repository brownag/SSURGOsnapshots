test_that("fiscal year calculation works", {
  expect_equal(fiscal_year_from_date("2025-09-30"), 2025)
  expect_equal(fiscal_year_from_date("2025-10-01"), 2026)
  expect_equal(fiscal_year_from_date("2025-12-30"), 2026)
  expect_equal(fiscal_year_from_date(as.Date("2025-10-01")), 2026)
  expect_equal(fiscal_year_from_date(), fiscal_year_from_date(Sys.Date()))
  
  expect_equal(fiscal_year_from_date("2025-06-15", fy_start_date = "2025-04-01"), 2026)
  expect_equal(fiscal_year_from_date("2025-04-01", fy_start_date = "2025-04-01"), 2026)
  
  expect_equal(fiscal_year_from_date("2024-12-31", fy_start_date = "2000-10-01"), 2025)
  expect_equal(fiscal_year_from_date("2025-01-01", fy_start_date = "2000-10-01"), 2025)
})

test_that("get_nationalmusym_lookup works", {
  if (!requireNamespace("gh", quietly = TRUE)) {
    skip("gh package not available")
  }
  
  # Mock download_snapshot_asset to return sample data
  sample_data <- data.frame(
    mukey = 1:3,
    nationalmusym = c("A", "B", "C"),
    areasymbol = c("AK", "AL", "AR")
  )
  mockery::stub(get_nationalmusym_lookup, "download_snapshot_asset", sample_data)
  
  data <- get_nationalmusym_lookup(2026, "brownag/SSURGOsnapshots")
  
  schema <- jsonlite::fromJSON(system.file("schemas", "nationalmusym-lookup.json", package = "SSURGOsnapshots"))
  expected_cols <- schema$data_structure$columns$name
  
  expect_s3_class(data, "data.frame")
  expect_equal(names(data), expected_cols)
  expect_gt(nrow(data), 0)
  expect_type(data$mukey, "integer")
  expect_type(data$nationalmusym, "character")
  expect_type(data$areasymbol, "character")
})

test_that("download_snapshot_asset caching works", {
  if (!requireNamespace("gh", quietly = TRUE)) {
    skip("gh package not available")
  }
  
  # Mock gh::gh to return a fake release
  fake_release <- list(
    list(
      tag_name = "FY2026",
      assets = list(
        list(name = "nationalmusym-lookup-FY2026.csv", browser_download_url = "fake_url")
      )
    )
  )
  mockery::stub(download_snapshot_asset, "gh::gh", fake_release)
  
  # Mock download.file to write sample data to destfile
  sample_csv <- "mukey,nationalmusym,areasymbol\n1,A,AK\n2,B,AL\n"
  mockery::stub(download_snapshot_asset, "download.file", function(url, destfile, ...) {
    writeLines(sample_csv, destfile)
  })
  
  data1 <- download_snapshot_asset("nationalmusym-lookup", 2026, "brownag/SSURGOsnapshots")
  
  data2 <- download_snapshot_asset("nationalmusym-lookup", 2026, "brownag/SSURGOsnapshots")
  
  expect_equal(data1, data2)
})