# 01_prepare.R
# Split input from answers, and keep only active lab codes.

library(readr)
library(dplyr)
source("R/functions.R")

answer_key <- read_csv("data-raw/answer_key.csv")
specimen   <- read_csv("data-raw/ship_specimen.csv")
loinc      <- read_csv("data-raw/Loinc.csv", guess_max = Inf)

# What the tool sees: label, specimen, cleaned search phrase
ship_input <- answer_key |>
  distinct(var_shortn, var_longn_eng) |>
  left_join(select(specimen, var_shortn, specimen_group), by = "var_shortn") |>
  mutate(query = clean_phrase(var_longn_eng))

# The expert answers: used only for grading
reference <- answer_key |>
  select(var_shortn, loinc)

# Active laboratory codes, only the columns we use
loinc_lab <- loinc |>
  filter(STATUS == "ACTIVE", CLASSTYPE == 1) |>
  select(LOINC_NUM, COMPONENT, PROPERTY, TIME_ASPCT, SYSTEM, SCALE_TYP, LONG_COMMON_NAME)

nrow(ship_input)   # expect 72
nrow(reference)    # expect 123
nrow(loinc_lab)    # expect 57195

write_csv(ship_input, "data/ship_input.csv")
write_csv(reference,  "data/reference.csv")
write_csv(loinc_lab,  "data/loinc_lab.csv")   # LOINC content: never on GitHub
