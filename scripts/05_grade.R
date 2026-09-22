# 05_grade.R
# Compare a search result with the experts' answers.
# This is the ONLY script that opens the reference.
#
# Results:
# text: top-1 = 66% (47/71), top-5 = 75% (53/71)
# llm : top-1 = ..%,         top-5 = ..%

library(readr)
library(dplyr)

arm <- "text"    # change to "llm" to grade the LLM arm

search    <- read_csv(paste0("data/search_", arm, ".csv"))
reference <- read_csv("data/reference.csv")
loinc_lab <- read_csv("data/loinc_lab.csv", guess_max = Inf)

# 1. Did the rules in 02_loinc.R remove any expert code?
reference |>
  filter(!is.na(loinc), !loinc %in% loinc_lab$LOINC_NUM)   # expect empty

# 2. The component of each expert code
expert <- reference |>
  filter(!is.na(loinc)) |>
  left_join(select(loinc_lab, LOINC_NUM, COMPONENT),
            by = c("loinc" = "LOINC_NUM")) |>
  select(var_shortn, component = COMPONENT) |>
  distinct()

# 3. Search results that match an expert component
hits <- inner_join(search, expert, by = c("var_shortn", "component"))

# 4. Each variable's best rank
best <- hits |>
  group_by(var_shortn) |>
  summarise(best_rank = min(rank))

# 5. Scores
n_mapped <- n_distinct(expert$var_shortn)
n_mapped                               # expect 71
sum(best$best_rank == 1) / n_mapped    # top-1
nrow(best) / n_mapped                  # top-5

# 6. Variables not found in the top 5
not_found <- expert |>
  distinct(var_shortn) |>
  filter(!var_shortn %in% best$var_shortn)

not_found
write_csv(not_found, paste0("data/not_found_", arm, ".csv"))

#Rerun for llm

arm <- "llm"    # to grade the LLM arm

search    <- read_csv(paste0("data/search_", arm, ".csv"))
reference <- read_csv("data/reference.csv")
loinc_lab <- read_csv("data/loinc_lab.csv", guess_max = Inf)

# 1. Did the rules in 02_loinc.R remove any expert code?
reference |>
  filter(!is.na(loinc), !loinc %in% loinc_lab$LOINC_NUM)   # expect empty

# 2. The component of each expert code
expert <- reference |>
  filter(!is.na(loinc)) |>
  left_join(select(loinc_lab, LOINC_NUM, COMPONENT),
            by = c("loinc" = "LOINC_NUM")) |>
  select(var_shortn, component = COMPONENT) |>
  distinct()

# 3. Search results that match an expert component
hits <- inner_join(search, expert, by = c("var_shortn", "component"))

# 4. Each variable's best rank
best <- hits |>
  group_by(var_shortn) |>
  summarise(best_rank = min(rank))

# 5. Scores
n_mapped <- n_distinct(expert$var_shortn)
n_mapped                               # expect 71
sum(best$best_rank == 1) / n_mapped    # top-1
nrow(best) / n_mapped                  # top-5

# 6. Variables not found in the top 5
not_found <- expert |>
  distinct(var_shortn) |>
  filter(!var_shortn %in% best$var_shortn)

not_found
write_csv(not_found, paste0("data/not_found_", arm, ".csv"))

