# 02_llm_names.R
# Ask the model once for the clinical name of every SHIP variable.
# These names are used only as a second search phrase in 03_search.R.
#
# Prompt and model were chosen on 5 tests that are not SHIP variables
# (BUN, ESR, trop I, PCT, D-dimer): llama3.2:3b 2/5, qwen2.5:7b 5/5.
# A LOINC-formal-name prompt and a class prompt were rejected there (about 2/5).

library(readr)
library(dplyr)
source("R/functions.R")

out_file <- "data/llm_answers.csv"
if (file.exists(out_file)) stop("Answers already saved. Delete the file only if you mean to ask again.")

ship_input <- read_csv("data/ship_input.csv")

llm_answers <- ship_input |>
  select(var_shortn, var_longn_eng) |>
  mutate(llm_answer = sapply(var_longn_eng, function(x) ask_llm(prompt_v2(x))),
         model      = "qwen2.5:7b",
         date       = Sys.Date())

write_csv(llm_answers, out_file)
