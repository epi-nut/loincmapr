# 09_diagnose.R
# One table, one row per SHIP variable:
# SHIP phrase | model's answer | text arm's top-1 | LLM arm's top-1 | expert
# Like 05_grade.R, this opens the reference: it is analysis, not the tool.

library(readr)
library(dplyr)

queries     <- read_csv("data/queries.csv")
llm_answers <- read_csv("data/llm_answers.csv")
search_text <- read_csv("data/search_text.csv")
search_llm  <- read_csv("data/search_llm.csv")
reference   <- read_csv("data/reference.csv")
loinc_lab   <- read_csv("data/loinc_lab.csv", guess_max = Inf)

# Expert components, one row per variable and component
expert_long <- reference |>
  filter(!is.na(loinc)) |>
  left_join(select(loinc_lab, LOINC_NUM, COMPONENT),
            by = c("loinc" = "LOINC_NUM")) |>
  select(var_shortn, component = COMPONENT) |>
  distinct()

# Same, squeezed into one row per variable for reading
expert_wide <- expert_long |>
  group_by(var_shortn) |>
  summarise(expert = paste(component, collapse = " | "))

# Top-1 of each arm
text_top1 <- search_text |> filter(rank == 1) |> select(var_shortn, text_top1 = component)
llm_top1  <- search_llm  |> filter(rank == 1) |> select(var_shortn, llm_top1  = component)

# Was each arm's top-1 one of the expert components?
text_ok <- search_text |> filter(rank == 1) |>
  semi_join(expert_long, by = c("var_shortn", "component")) |> pull(var_shortn)
llm_ok  <- search_llm  |> filter(rank == 1) |>
  semi_join(expert_long, by = c("var_shortn", "component")) |> pull(var_shortn)

# Put it all side by side
diag <- queries |>
  select(var_shortn, query) |>
  left_join(select(llm_answers, var_shortn, llm_answer), by = "var_shortn") |>
  left_join(text_top1,   by = "var_shortn") |>
  left_join(llm_top1,    by = "var_shortn") |>
  left_join(expert_wide, by = "var_shortn") |>
  mutate(text_ok = var_shortn %in% text_ok,
         llm_ok  = var_shortn %in% llm_ok)

View(diag)
write_csv(diag, "data/diagnostic.csv")

# Where the text arm was right but the LLM arm was wrong
diag |> filter(text_ok, !llm_ok) |> View()

# Where the LLM arm fixed a text-arm miss
diag |> filter(!text_ok, llm_ok) |> View()

# Counts of the four combinations
table(text = diag$text_ok, llm = diag$llm_ok)

# Ceiling of the combined shortlist: text top-5 + LLM top-5
combined <- bind_rows(search_text, search_llm) |>
  distinct(var_shortn, component)

found <- combined |>
  semi_join(expert_long, by = c("var_shortn", "component")) |>
  distinct(var_shortn)

nrow(found) / 71

library(readr); library(dplyr)
loinc_lab <- read_csv("data/loinc_lab.csv", guess_max = Inf)

classes <- sort(unique(loinc_lab$CLASS))
length(classes)
head(classes, 40)

reference <- read_csv("data/reference.csv")

reference |>
  filter(!is.na(loinc)) |>
  left_join(select(loinc_lab, LOINC_NUM, CLASS), by = c("loinc" = "LOINC_NUM")) |>
  count(CLASS, sort = TRUE)

classes <- sort(unique(loinc_lab$CLASS))
length(classes)
head(classes, 40)

source("R/functions.R")

prompt_class <- function(label, classes) {
  paste0("Which LOINC CLASS does this laboratory test belong to: '", label, "'?\n",
         "Choose exactly one from this list:\n",
         paste(classes, collapse = ", "), "\n",
         "Answer with the class code only, no explanation.")
}

dev_tests <- c("BUN", "ESR", "trop I", "PCT", "D-dimer")
sapply(dev_tests, function(x) ask_llm(prompt_class(x, classes)))

git --version
