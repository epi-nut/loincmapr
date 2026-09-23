# 07_grade.R
# Code-level grading: did the chosen LOINC code match one of the expert's codes?
# Opens the reference.

library(readr)
library(dplyr)
library(stringr)

run <- "choices"

choices   <- read_csv(paste0("data/", run, ".csv"))
reference <- read_csv("data/reference.csv")

expert <- reference |> filter(!is.na(loinc))

graded <- choices |>
  filter(var_shortn %in% expert$var_shortn) |>
  rowwise() |>
  mutate(
    right_codes = list(expert$loinc[expert$var_shortn == var_shortn]),
    ceiling     = if (is.na(candidates)) FALSE 
                  else any(str_split_1(candidates, ";") %in% right_codes),    
    baseline    = baseline_code %in% right_codes,
    llm         = llm_code %in% right_codes
  ) |>
  ungroup()

nrow(graded)                                     # expect 71
colSums(select(graded, ceiling, baseline, llm))  # number right
colMeans(select(graded, ceiling, baseline, llm)) # share right

sum(choices$n_candidates == 0)
choices |> filter(n_candidates == 0) |> pull(var_shortn)
write_csv(select(graded, -right_codes), paste0("data/", run, "_graded.csv"))
