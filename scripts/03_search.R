# 03_search.R
# For each variable, search LOINC twice: with the SHIP phrase and with the
# model's name (02). Only components with the right specimen are searched.

library(readr)
library(dplyr)
source("R/functions.R")

ship_input  <- read_csv("data/ship_input.csv")
llm_answers <- read_csv("data/llm_answers.csv")
loinc_lab   <- read_csv("data/loinc_lab.csv")

input <- ship_input |>
  left_join(select(llm_answers, var_shortn, llm_answer), by = "var_shortn") |>
  mutate(llm_query = clean_phrase(llm_answer))

results <- list()
for (i in 1:nrow(input)) {
  systems <- crosswalk[[input$specimen_group[i]]]
  comps   <- unique(loinc_lab$COMPONENT[loinc_lab$SYSTEM %in% systems])

  results[[i]] <- tibble(
    var_shortn = input$var_shortn[i],
    arm        = rep(c("text", "llm"), each = 5),
    rank       = rep(1:5, times = 2),
    component  = c(top5(input$query[i], comps),
                   top5(input$llm_query[i], comps))
  )
}
search <- bind_rows(results)

nrow(search)   # expect 720: 72 variables x 2 searches x 5
write_csv(search, "data/search.csv")
