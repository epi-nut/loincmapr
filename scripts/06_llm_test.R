# 06_llm_test.R
# Develop the prompt on lab tests that are NOT SHIP variables,
# so the prompt is never tuned on the test set.
#
# Dev set results with prompt_v2:
# llama3.2:3b -> 2 right, 1 declined, 2 wrong (PCT -> "Prothrombin Time")
# qwen2.5:7b  -> 5 right
# Decision: freeze prompt_v2 + qwen2.5:7b

source("R/functions.R")

dev_tests <- c("BUN", "ESR", "trop I", "PCT", "D-dimer")
# Correct: blood urea nitrogen, erythrocyte sedimentation rate,
#          troponin I, procalcitonin, D-dimer

prompt_v2("BUN")   # look at the full question first

answers_3b <- sapply(dev_tests,
                     function(x) ask_llm(prompt_v2(x), model = "llama3.2:3b"))
answers_3b

answers_7b <- sapply(dev_tests,
                     function(x) ask_llm(prompt_v2(x), model = "qwen2.5:7b"))
answers_7b
