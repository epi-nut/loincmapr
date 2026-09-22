# Can a local LLM help map laboratory variables to LOINC?

A benchmark against a published expert mapping.

[your name] · [date]

## Summary

I tested whether a language model running on my own laptop can suggest LOINC
codes for laboratory variables, using the published expert mapping of the
SHIP-START-4 data dictionary as the answer key. Across 72 variables, plain
text matching found the expert's code in its top 5 for 75% of them. Sending
the variable label through the model first made that worse, down to 58%,
because the model answers in clinical language and LOINC components use
formal terms. Adding the model's candidates to the text-matching candidates
raised the ceiling to 77%, so the model contributes something, but not much.

## Question

How well does an automated pipeline reproduce the published expert LOINC
mapping for the SHIP-START-4 laboratory data dictionary, and does a local
language model add anything over deterministic text matching?

## Background

A cohort study names its own variables. SHIP records alanine
aminotransferase as `alat_s`, labelled `LAB: alanine aminotransferase
(ALAT/GPT) (µkatal/l)`. That label means something to the study team and
nothing to a computer elsewhere, so no software can tell that another
study's ALT variable measures the same thing. LOINC fixes this by giving
each laboratory test an international code, which is what makes variables
findable and comparable across studies.

Someone has to attach those codes, and today that someone is an expert. The
work is slower than it sounds. LOINC distinguishes tests by six parts:
component, property, time, system, scale and method. SHIP's label for
`alat_s` says nothing about the method, and LOINC has separate codes for ALT
measured with and without pyridoxal-5'-phosphate. The experts could not
choose, so they listed both. Of the 72 SHIP laboratory variables, 39 needed
this kind of multi-code mapping, 32 mapped to a single code, and one could
not be mapped at all.

Inau and colleagues published that mapping for SHIP-START-4. An earlier
abstract from the same group calls the manual annotation a time-consuming
clerical burden and reports about 10% of the SHIP-4 metadata annotated at
the time. The 2025 paper covers only a pilot phase and says many more
measurands still need evaluation. That is the bottleneck this project tests
an LLM against.

## Data

| File | Source | Licence |
|---|---|---|
| `data-raw/answer_key.csv` | Transcribed from Inau et al., Zenodo 15711189, Tables 3 to 5 | CC BY 4.0 |
| `data-raw/Loinc.csv` | LOINC release [VERSION], loinc.org | LOINC licence, not redistributed here |

The answer key has 123 variable-code pairs for 72 variables: 32 with one
code, 39 with two or three, and `sg_u` with none.

`01_split.R` writes two files that are never used together:

- `data/ship_input.csv` holds the variable name and label. This is all the
  pipeline and the model ever see.
- `data/reference.csv` holds the expert answers. Only the grading script
  opens it.

## Method

1. **Filtering** (`02_loinc.R`). Keep active laboratory codes
   (`CLASSTYPE == 1`): 101,632 codes become 57,195, with 25,374 different
   component names. Both rules come from LOINC's own definitions, so they
   carry no knowledge of the answers.
2. **Cleaning** (`03_clean.R`). Lowercase, drop the `LAB:` prefix, remove
   brackets and the words serum and urine. Unit and specimen are copied into
   their own columns first, because the cleaning would otherwise destroy
   them.
3. **Search** (`04_search.R`). Jaro-Winkler distance between the phrase and
   every component name, keeping the 5 closest.
4. **LLM translation** (`07_llm_translate.R`, `08_search_llm.R`). The model
   reads the original SHIP label and returns a clinical name. The same
   cleaning and the same search then run on its answer, so the only
   difference between the two arms is the phrase.
5. **Grading** (`05_grade.R`). Top-1 and top-5 agreement with the expert
   components, over the 71 mapped variables.

The model is `qwen2.5:7b`, run locally through Ollama at temperature 0. No
data leaves the machine. Model name, date and prompt are stored with the
answers.

## Results

n = 71 mapped variables.

| Arm | Top-1 | Top-5 |
|---|---|---|
| Text matching on the SHIP label | 66% (47/71) | 75% (53/71) |
| LLM clinical name replaces the label | 51% (36/71) | 58% (41/71) |
| Same, after removing filler words | 54% (38/71) | 58% (41/71) |
| Text candidates plus LLM candidates | | 77% (55/71) |

Prompt and model were chosen on a development set of five laboratory tests
that are not SHIP variables, so the SHIP data was never used for tuning.

| Variant | Development set | Decision |
|---|---|---|
| `llama3.2:3b`, clinical-name prompt | 2/5 | rejected |
| `qwen2.5:7b`, clinical-name prompt | 5/5 | used |
| `qwen2.5:7b`, LOINC formal-name prompt | about 2/5, invented "Benzeneurea" for BUN | rejected |
| `qwen2.5:7b`, LOINC class assignment | 2/5, though every answer was a real class | rejected |

Both rejected variants were rejected before they touched the SHIP data.

The same prompt at temperature 0 returned identical answers in five repeated
calls.

## What this shows

Text matching does most of the work here, because SHIP's wording is usually
close to LOINC's. Haemoglobin finds Hemoglobin despite the spelling.

Replacing the SHIP label with the model's answer costs more than it gains.
The model says White Blood Cell Count where LOINC says Leukocytes, and it
adds words like Measurement and Test that pull the string comparison off
target. Of the 47 variables text matching already got right, several were
lost this way.

Keeping both sets of candidates is the version that helps. It found 2
variables that text matching alone never reached, and by construction it
cannot do worse.

The pattern across all five experiments is the same. The model reproduces
knowledge it has, such as the clinical names of tests, and invents what it
does not have, such as LOINC's formal vocabulary and its class structure.
That is a reason to ground every suggestion in the real catalogue and to
grade it, rather than to trust it.

Sixteen variables were missed by both arms: the percentage variables, where
LOINC writes Basophils/100 leukocytes and SHIP writes basophils; several
synonyms; and the three GFR variables.

## Data quality of the published reference

The CSV and PDF versions of the same published mapping disagree. Every
complex variable in the CSV had a row count that did not match its stated
cardinality, and some relation symbols differ between the two versions. I
used the PDF as the reference and transcribed it into a single tidy file.
[ADD YOUR COUNTS AND ONE EXAMPLE.]

## Limitations

72 variables, one data dictionary, one model, one LOINC version. None of
this generalises further without more testing.

The answer key was transcribed by hand from a PDF, so transcription errors
are possible.

The pipeline suggests candidates for an expert to review. It does not
replace expert curation, and because it proposes one component per variable,
it can only be partly right on the 39 complex mappings.

Automated terminology mapping has been studied before. I claim no novelty
for the approach, only a measurement against this published reference.

## Repository

```
R/functions.R      shared functions
scripts/01 to 09   the pipeline, run in order
data-raw/          inputs, without the LOINC file for licence reasons
data/              everything the scripts produce
```

## How to run

1. Install R, RStudio and Ollama, then `ollama pull qwen2.5:7b`
2. Download `Loinc.csv` from loinc.org and put it in `data-raw/`
3. `install.packages(c("readr","dplyr","stringr","stringdist","httr2"))`
4. Run `scripts/01_split.R` through `09_diagnose.R` in order. Run
   `05_grade.R` twice, once with `arm <- "text"` and once with
   `arm <- "llm"`.
