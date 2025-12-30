test_that("fiscal year calculation works", {
  # Test fiscal year from date
  expect_equal(fiscal_year_from_date("2025-09-30"), 2025)
  expect_equal(fiscal_year_from_date("2025-10-01"), 2026)
  expect_equal(fiscal_year_from_date("2025-12-30"), 2026)
})