# 03_clean.R
# Turn SHIP labels into clean search phrases.
# Unit and specimen are copied into their own columns first,
# because the cleaning removes them from the phrase.

library(readr)
library(dplyr)
source("R/functions.R")

ship_input <- read_csv("data/ship_input.csv")

queries <- ship_input |>
  mutate(
    unit     = str_extract(str_to_lower(var_longn_eng), "\\([^)]*\\)$"),
    specimen = str_extract(str_to_lower(var_longn_eng), "\\b(serum|urine)\\b"),
    query    = clean_phrase(var_longn_eng)
  )

table(queries$specimen, useNA = "ifany")   # expect serum 7, urine 15, NA 50
View(queries)

write_csv(queries, "data/queries.csv")
