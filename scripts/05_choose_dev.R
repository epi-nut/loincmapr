# 05_choose_dev.R
# Try the "choose a code" prompt on 5 tests that are NOT SHIP variables,
# before it ever touches the SHIP data.
#
# Result (qwen2.5:7b): 5/5 sensible, valid codes; the unit was used correctly;
# it chose confidently where method or unit was ambiguous (troponin, D-dimer).

library(readr)
library(dplyr)
source("R/functions.R")

loinc_lab <- read_csv("data/loinc_lab.csv")

dev <- tibble(
  label    = c("urea nitrogen (mg/dl)", "erythrocyte sedimentation rate (mm/h)",
               "troponin I (ng/l)", "procalcitonin (ng/ml)", "D-dimer (mg/l)"),
  specimen = c("serum_plasma", "blood", "serum_plasma", "serum_plasma", "ppp")
)

for (i in 1:nrow(dev)) {
  systems <- crosswalk[[dev$specimen[i]]]
  comps   <- top5(clean_phrase(dev$label[i]),
                  unique(loinc_lab$COMPONENT[loinc_lab$SYSTEM %in% systems]))
  cands   <- candidate_codes(dev$label[i], comps, systems, loinc_lab)
  answer  <- ask_llm(prompt_choose(dev$label[i], dev$specimen[i], cands))
  code    <- str_extract(answer, "\\d+-\\d")

  cat("\n", dev$label[i], "\n  model said:", answer,
      "\n  that code is:", cands$LONG_COMMON_NAME[match(code, cands$LOINC_NUM)], "\n")
}
