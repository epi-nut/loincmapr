# 01_split.R
# Separate the tool's input from the expert answers,
# so the tool can never see the answers.

library(readr)
library(dplyr)

# Answer key, transcribed from the published PDF (Tables 3-5)
answer_key <- read_csv("data-raw/answer_key.csv")

nrow(answer_key)                    # expect 123
n_distinct(answer_key$var_shortn)   # expect 72

# Input: what SHIP published, one row per variable
ship_input <- answer_key |>
  select(var_shortn, var_longn_eng) |>
  distinct()

# Reference: the expert answers, used ONLY in 05_grade.R
reference <- answer_key |>
  select(var_shortn, loinc, relation, cardinality, mapping_type)

nrow(ship_input)   # expect 72
nrow(reference)    # expect 123

write_csv(ship_input, "data/ship_input.csv")
write_csv(reference,  "data/reference.csv")
