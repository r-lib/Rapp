test_that("yaml12 snapshots select the emitter contract", {
  expect_identical(yaml12_snapshot_variant("0.1.0"), "yaml12-0.1")
  expect_identical(yaml12_snapshot_variant("0.1.0.9000"), "yaml12-0.2")
  expect_identical(yaml12_snapshot_variant("0.2.0"), "yaml12-0.2")
})
