# 08_search_llm.R
# ARM 2 (LLM): search LOINC with the model's answers,
# using exactly the same cleaning and search code as ARM 1.

library(readr)
library(dplyr)
source("R/functions.R")

llm_answers <- read_csv("data/llm_answers.csv")
loinc_lab   <- read_csv("data/loinc_lab.csv", guess_max = Inf)
components  <- unique(loinc_lab$COMPONENT)

llm_answers <- llm_answers |>
  mutate(query = clean_phrase(llm_answer))

results <- list()
for (i in 1:nrow(llm_answers)) {
  results[[i]] <- tibble(
    var_shortn = llm_answers$var_shortn[i],
    rank       = 1:5,
    component  = top5(llm_answers$query[i], components)
  )
}
search_llm <- bind_rows(results)

nrow(search_llm)   # expect 360
write_csv(search_llm, "data/search_llm.csv")
