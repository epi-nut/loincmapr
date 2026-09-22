# 07_llm_translate.R
# Ask the model for the clinical name of every SHIP variable.
# Input only: the model never sees the reference.
# The saved file IS the data: it only runs once, to avoid
# rerunning and picking the "best" run.

library(readr)
library(dplyr)
source("R/functions.R")

model_used <- "qwen2.5:7b"
out_file   <- "data/llm_answers.csv"

queries <- read_csv("data/queries.csv")

if (!file.exists(out_file)) {

  start <- Sys.time()

  llm_answers <- queries |>
    select(var_shortn, var_longn_eng) |>
    mutate(llm_answer = sapply(var_longn_eng,
                               function(x) ask_llm(prompt_v2(x), model = model_used)),
           model = model_used,
           date  = Sys.Date())

  print(Sys.time() - start)
  write_csv(llm_answers, out_file)

} else {
  message("llm_answers.csv already exists: not asking the model again.")
}

View(read_csv(out_file))
