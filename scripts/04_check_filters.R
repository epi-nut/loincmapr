# 04_check_filters.R
# Do the axis filters ever throw away an expert's code? Opens the reference.

library(readr)
library(dplyr)
source("R/functions.R")

reference  <- read_csv("data/reference.csv")
ship_input <- read_csv("data/ship_input.csv")
axes       <- read_csv("data-raw/ship_axes.csv")
loinc_lab  <- read_csv("data/loinc_lab.csv")

reference |>
  filter(!is.na(loinc)) |>
  left_join(loinc_lab, by = c("loinc" = "LOINC_NUM")) |>
  left_join(select(ship_input, var_shortn, specimen_group), by = "var_shortn") |>
  left_join(axes, by = "var_shortn") |>
  rowwise() |>
  mutate(
    ok_system   = SYSTEM %in% crosswalk[[specimen_group]],
    ok_time     = TIME_ASPCT == time,
    ok_scale    = SCALE_TYP %in% allowed_scale(scale),
    ok_property = is.null(allowed_property(unit)) || PROPERTY %in% allowed_property(unit)
  ) |>
  ungroup() |>
  filter(!(ok_system & ok_time & ok_scale & ok_property)) |>
  select(var_shortn, loinc, SYSTEM, TIME_ASPCT, SCALE_TYP, PROPERTY, unit,
         ok_system, ok_time, ok_scale, ok_property) |>
  print(n = Inf)

# Result: 0 expert codes removed (after adding Ser/Plas/Bld to serum_plasma
# and letting Qn also accept SemiQn). The unit-to-property rule never removed one.
