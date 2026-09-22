# R/functions.R
# Functions shared by the scripts.
# Only library() lines and function definitions here:
# no data loading, no loops, no source().

library(httr2)
library(stringr)
library(stringdist)

# Send one question to the local model, return its answer
ask_llm <- function(prompt, model = "qwen2.5:7b") {
  resp <- request("http://localhost:11434/api/generate") |>
    req_body_json(list(model   = model,
                       prompt  = prompt,
                       stream  = FALSE,
                       options = list(temperature = 0))) |>
    req_perform()
  resp_body_json(resp)$response
}

# The frozen prompt: same wording for every variable
prompt_v2 <- function(label) {
  paste0("What is the standard clinical name of this laboratory test: '",
         label,
         "'? Write out any abbreviations in full. ",
         "Answer with the name only, no explanation.")
}
# Variant 3: ask for LOINC's formal component name

# Same cleaning for every phrase, whether from SHIP or the model
#clean_phrase <- function(x) {
#  x |>
 #   str_to_lower() |>
 #   str_remove("^lab: ") |>
  #  str_remove_all("\\([^)]*\\)") |>
   # str_remove_all("\\b(serum|urine)\\b") |>
    #str_squish()
#}

clean_phrase <- function(x) {
  x |>
    str_to_lower() |>
    str_remove("^lab: ") |>
    str_remove_all("\\([^)]*\\)") |>
    str_remove_all("\\b(serum|urine)\\b") |>
    str_remove_all("\\b(test|measurement|level)\\b") |>
    str_squish()
}

# The 5 most similar LOINC component names for one phrase
top5 <- function(phrase, components) {
  dist <- stringdist(phrase, tolower(components), method = "jw")
  components[order(dist)][1:5]
  
  library(readr); library(dplyr); library(stringr)
  source("R/functions.R")
  loinc_lab <- read_csv("data/loinc_lab.csv", guess_max = Inf)
  
  loinc_lab |>
    filter(str_detect(COMPONENT, "^(Urea nitrogen|Erythrocyte sedimentation rate|Troponin I|Procalcitonin|Fibrin D-dimer)")) |>
    distinct(COMPONENT)
}

dev_tests <- c("BUN", "ESR", "trop I", "PCT", "D-dimer")

answers_v3 <- sapply(dev_tests, function(x) ask_llm(prompt_v2(x)))
answers_v3

source("R/functions.R")
replicate(5, ask_llm(prompt_v2("BUN")))