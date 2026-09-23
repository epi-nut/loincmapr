# R/functions.R
# Shared functions and settings. No data loading here.

library(dplyr)
library(httr2)
library(stringr)
library(stringdist)

# Ask the local model one question
ask_llm <- function(prompt, model = "qwen2.5:7b") {
  resp <- request("http://localhost:11434/api/generate") |>
    req_body_json(list(model = model, prompt = prompt, stream = FALSE,
                       options = list(temperature = 0))) |>
    req_perform()
  resp_body_json(resp)$response
}

# Prompt 1: ask for the clinical name of the test
prompt_v2 <- function(label) {
  paste0("What is the standard clinical name of this laboratory test: '",
         label, "'? Write out any abbreviations in full. ",
         "Answer with the name only, no explanation.")
}

# Prompt 2: choose one LOINC code from a list of real candidates
prompt_choose <- function(label, specimen, candidates) {
  paste0("A cohort study has this laboratory variable: '", label,
         "' (specimen: ", specimen, ").\n",
         "Which of these LOINC codes matches it best? Use the unit to decide.\n",
         paste0(candidates$LOINC_NUM, ": ", candidates$LONG_COMMON_NAME, collapse = "\n"),
         "\nAnswer with the LOINC code only, for example 1234-5, ",
         "or NONE if no code matches.")
}

# Same cleaning for SHIP labels and model answers
clean_phrase <- function(x) {
  x |>
    str_to_lower() |>
    str_remove("^lab: ") |>
    str_remove_all("\\([^)]*\\)") |>
    str_remove_all("\\b(serum|urine|test|measurement|level)\\b") |>
    str_squish()
}

# The 5 most similar component names
top5 <- function(phrase, components) {
  dist <- stringdist(phrase, tolower(components), method = "jw")
  components[order(dist)][1:5]
}

# Real candidate codes: the given components, the right specimen,
# ordered by how similar their long name is to the label
candidate_codes <- function(label, comps, systems, loinc_lab, n = 15) {
  loinc_lab |>
    filter(COMPONENT %in% comps, SYSTEM %in% systems) |>
    mutate(dist = stringdist(clean_phrase(label), tolower(LONG_COMMON_NAME),
                             method = "jw")) |>
    arrange(dist) |>
    head(n)
}

# LOINC SYSTEM values that count as a match for each SHIP specimen
crosswalk <- list(
  blood              = c("Bld"),
  erythrocytes       = c("RBC", "Bld"),
  serum_plasma       = c("Ser", "Ser/Plas", "Plas", "Ser/Plas/Bld"),
  serum_plasma_blood = c("Ser/Plas/Bld", "Ser/Plas", "Ser", "Plas", "Bld"),
  ppp                = c("PPP", "Plas"),
  urine              = c("Urine")
)

# Unit -> allowed LOINC PROPERTY values (from LOINC's property definitions).
# "%" is ambiguous in LOINC, so it allows several fraction/ratio properties.
unit_property <- list(
  "mmol/l" = "SCnc", "µmol/l" = "SCnc", "pmol/l" = "SCnc",
  "g/l" = "MCnc", "mg/l" = "MCnc", "µg/l" = "MCnc", "mg/dl" = "MCnc",
  "µkatal/l" = "CCnc",
  "Gpt/l" = "NCnc", "Tpt/l" = "NCnc", "/µl" = "NCnc", "Zellen/µl" = "NCnc",
  "fl" = "EntVol", "fmol" = "EntSub",
  "mU/l" = "ACnc", "U/ml" = "ACnc",
  "s" = "Time",
  "mmol/mol" = "SFr",
  "ml/min" = c("ArVRat", "VRat"), "ml/min/1,73qm" = c("ArVRat", "VRat"),
  "pos/neg" = "PrThr",
  "%" = c("NFr", "MFr", "VFr", "SFr", "RelTime", "Ratio")
)

# Allowed properties for a unit, or NULL = no property filter
allowed_property <- function(unit) {
  if (is.na(unit) || is.null(unit_property[[unit]])) return(NULL)
  unit_property[[unit]]
}

# A study's "Qn" also accepts LOINC's semi-quantitative scale (test strips)
allowed_scale <- function(scale) {
  if (scale == "Qn") c("Qn", "SemiQn") else scale
}

# Candidate codes filtered on all known axes: specimen, time, scale, property
candidate_codes_axes <- function(label, comps, systems, time, scale, props,
                                 loinc_lab, n = 15) {
  cands <- loinc_lab |>
    filter(COMPONENT %in% comps, SYSTEM %in% systems,
           TIME_ASPCT == time, SCALE_TYP %in% allowed_scale(scale))
  if (!is.null(props)) cands <- filter(cands, PROPERTY %in% props)
  cands |>
    mutate(dist = stringdist(clean_phrase(label), tolower(LONG_COMMON_NAME),
                             method = "jw")) |>
    arrange(dist) |>
    head(n)
}
