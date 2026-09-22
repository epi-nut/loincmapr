# 02_loinc.R
# Load the LOINC catalogue and keep only active laboratory codes.
# Both rules come from LOINC's own definitions, not from the answers.

library(readr)
library(dplyr)

loinc_cat <- read_csv("data-raw/Loinc.csv", guess_max = Inf)

nrow(loinc_cat)   # expect 101632

# Cross-table of status by class type (1 = laboratory)
table(loinc_cat$STATUS, loinc_cat$CLASSTYPE)

loinc_lab <- loinc_cat |>
  filter(STATUS == "ACTIVE", CLASSTYPE == 1)

nrow(loinc_lab)   # expect 57195

# LOINC content: never upload this file to GitHub (licence)
write_csv(loinc_lab, "data/loinc_lab.csv")
