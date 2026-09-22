# 04_search.R
# ARM 1 (text only): for each SHIP variable, find the 5 most
# similar LOINC component names. Never opens the reference.

library(readr)
library(dplyr)
source("R/functions.R")

queries    <- read_csv("data/queries.csv")
loinc_lab  <- read_csv("data/loinc_lab.csv", guess_max = Inf)
components <- unique(loinc_lab$COMPONENT)

length(components)                 # size of the haystack
top5("haemoglobin", components)    # test on one example first

results <- list()
for (i in 1:nrow(queries)) {
  results[[i]] <- tibble(
    var_shortn = queries$var_shortn[i],
    rank       = 1:5,
    component  = top5(queries$query[i], components)
  )
}
search_text <- bind_rows(results)

nrow(search_text)   # expect 360 (72 x 5)
write_csv(search_text, "data/search_text.csv")
