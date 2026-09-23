# 06_choose.R
# The model maps each SHIP variable to one LOINC code, choosing from real
# candidates filtered on specimen, time, scale and property
# (property from SHIP's unit, via the rule table in functions.R).
# Runs the model once, then saves.

library(readr)
library(dplyr)
source("R/functions.R")


ship_input <- read_csv("data/ship_input.csv")
axes       <- read_csv("data-raw/ship_axes.csv")
search     <- read_csv("data/search.csv")
loinc_lab  <- read_csv("data/loinc_lab.csv")

input <- left_join(ship_input, axes, by = "var_shortn")

results <- list()
for (i in 1:nrow(input)) {
  v     <- input$var_shortn[i]
  label <- input$var_longn_eng[i]
  spec  <- input$specimen_group[i]

  comps <- unique(search$component[search$var_shortn == v])
  cands <- candidate_codes_axes(label, comps, crosswalk[[spec]],
                                input$time[i], input$scale[i],
                                allowed_property(input$unit[i]), loinc_lab)

  answer <- ask_llm(prompt_choose(label, spec, cands))
  code   <- str_extract(answer, "\\d+-\\d")

  results[[i]] <- tibble(
    var_shortn    = v,
    n_candidates  = nrow(cands),
    baseline_code = cands$LOINC_NUM[1],   # rules + most similar long name: no model
    llm_answer    = answer,
    llm_code      = ifelse(code %in% cands$LOINC_NUM, code, NA),
    candidates    = paste(cands$LOINC_NUM, collapse = ";")
  )
  cat(i, "")
}

choices <- bind_rows(results)
saveRDS(choices, "data/choices.rds")   # backup first
write_csv(choices, "data/choices.csv")
