# Can a local LLM help map laboratory variables to LOINC?

A benchmark against a published expert mapping.

Khalid Iqbal · 23 September 2026

## Summary

I tested whether a language model running on my laptop can map a cohort
study's laboratory variables to LOINC codes. The answer key is the published
expert mapping of the SHIP-START-4 data dictionary: 72 variables, 71 of them
mapped.

The pipeline finds candidate codes by text search and then picks one. With
candidates filtered only by specimen, the model picked the right code for 33
variables and a naive rule-based choice for 18. I then added rule-based
filters for time, scale and the property implied by the unit. Rules alone
reached 47, the model 46.

So the model's early lead came from knowing what units mean, and a 20-line
rule table knows that too. The real limit is finding candidates: for 14
variables the right code never made the list. The project was designed only for 
educational purposes.

## Question

How closely can an automated pipeline reproduce the published LOINC mapping
of the SHIP-START-4 laboratory data dictionary, and does a local language
model add anything that deterministic rules don't?

## Background

Cohort studies name their own variables. SHIP stores alanine
aminotransferase as `alat_s`, labelled `LAB: alanine aminotransferase
(ALAT/GPT) (µkatal/l)`. The study team knows what that means. Software
elsewhere doesn't. LOINC fixes this by giving each laboratory test an
international code, so the same measurement can be found and compared
across studies.

An expert assigns those codes by hand, and it takes longer than it sounds.
LOINC separates tests along six axes: component, property, time, system
(specimen), scale and method. SHIP's `alat_s` label doesn't say which method
was used, and LOINC has separate codes for ALT with and without
pyridoxal-5'-phosphate. The experts couldn't choose, so they listed both. Of
the 72 variables, 32 got one code, 39 got two or three, and 1 got none.

Inau and colleagues published that mapping. An earlier abstract from the
same group calls the manual annotation a time-consuming clerical burden, and
the 2025 paper says it covers a pilot phase, with many more measurands still
to do.

## Data

| File | Source | Licence |
|---|---|---|
| `data-raw/answer_key.csv` | Transcribed from Inau et al., Zenodo 15711189, Tables 3 to 5 | CC BY 4.0 |
| `data-raw/ship_specimen.csv`, `ship_axes.csv` | Transcribed from the SHIP side of the same tables: specimen, time, scale, unit | CC BY 4.0 |
| `data-raw/Loinc.csv` | LOINC release [VERSION], loinc.org | LOINC licence, not included |

Expert mapping: https://zenodo.org/records/15711189

The pipeline only ever reads `data/ship_input.csv`, which holds each
variable's name, label, specimen and cleaned search phrase. The expert
answers sit in `data/reference.csv`, and only the checking and grading
scripts open that file.

## Method

| Script | What it does | Model calls |
|---|---|---|
| `01_prepare.R` | Separates input from answers; keeps active lab codes (101,632 → 57,195) | none |
| `02_llm_names.R` | Model writes a clinical name for each variable | 72, once |
| `03_search.R` | Two text searches per variable, with SHIP's label and with the model's name, among components of the right specimen | none |
| `04_check_filters.R` | Confirms no filter throws away an expert code | none |
| `05_choose_dev.R` | Tries the choosing prompt on 5 tests that aren't SHIP variables | 5 |
| `06_choose.R` | Model picks one code from up to 15 real candidates | 72, once |
| `07_grade.R` | Scores the ceiling, the rule-based choice and the model against the experts | none |

**Candidates.** Every component either search found becomes a set of
candidate codes, which rules then filter on four axes:

- **Specimen**, via a crosswalk from SHIP's specimen to LOINC's `SYSTEM`.
- **Time**: point-in-time for all 72 variables.
- **Scale**: the study's `Qn` also accepts LOINC's `SemiQn`, which is how
  LOINC classes test strips.
- **Property**, from SHIP's unit through a fixed table. mmol/l means
  substance concentration, g/l mass concentration, µkatal/l catalytic
  concentration. `%` allows six properties, because LOINC uses it for
  several kinds of quantity.

What's left gets sorted by how similar each code's long name is to SHIP's
label, and the top 15 go forward.

**Choosing.** The rule-based choice takes the first candidate. The model
gets SHIP's full label, the specimen and all 15 candidates with their long
names, and replies with one code or NONE. Anything not on the list is
discarded.

The model is `qwen2.5:7b`, run locally through Ollama at temperature 0, so
no data leaves the machine. I chose the prompts and the model on a
development set of five lab tests that aren't SHIP variables, before
running anything on SHIP.

## Results

All figures are out of the 71 mapped variables.

**Finding candidates.** Was the right component among the top 5?

| Search | Found |
|---|---|
| SHIP's label | 77% (55/71) |
| SHIP's label plus the model's name | 80% (57/71) |

**Choosing the code.** Was the chosen code one of the expert's?

| Candidates filtered by | Ceiling | Rule-based choice | Model |
|---|---|---|---|
| Specimen only | 80% (57) | 25% (18) | 46% (33) |
| Specimen, time, scale, property | 80% (57) | **66% (47)** | **65% (46)** |

The ceiling is the share of variables with a right code somewhere in the
candidate list. No chooser can beat it.

**Tried on the development set:**

| Variant | Development set | Decision |
|---|---|---|
| `llama3.2:3b`, clinical-name prompt | 2/5 | dropped |
| `qwen2.5:7b`, clinical-name prompt | 5/5 | used |
| `qwen2.5:7b`, LOINC formal-name prompt | about 2/5; called BUN "Benzeneurea" | dropped |
| `qwen2.5:7b`, LOINC class assignment | 2/5 | dropped |
| `qwen2.5:7b`, choose a code from a list | 5/5 | used |

When the model's names replaced SHIP's labels in the search, instead of
running alongside them, only 59% of components were found, against 77%.
Repeated calls with the same prompt at temperature 0 gave identical answers.

## What this shows

SHIP's own labels find most candidates, because SHIP's wording is usually
close to LOINC's. The model's names add 2 more, where the vocabularies part
ways. `quick` is one: the model calls it prothrombin time, which is what
LOINC's long name says.

For choosing between codes, the model beat a naive choice because it knows
that mmol/l means moles per volume. Once a rule table encoded the same
thing, the naive choice caught up. For mappings that follow from a
definition, a rule gives the same answer every time, runs instantly, and
anyone can read why it chose what it chose.

The model was good at picking from real options and bad at producing
LOINC's vocabulary from memory, where it made names up. Every suggestion
has to be checked against the catalogue.

Finding candidates is where the pipeline loses most. For 14 variables the
right code was never on the list, and 7 had no candidates at all after
filtering: `ptt`, `lip_s`, `ne_pct_e`, `ly_pct_e`, `gfr_larsson_t`,
`gfrmdrd` and `gfrcapa`. They're coagulation tests, synonyms (lipase is
"triacylglycerol lipase" in LOINC), percentages that LOINC writes as "/100
leukocytes", and estimated GFR.

## Data quality of the published reference

- The CSV and PDF versions of the mapping disagree. In the CSV, every
  complex variable had a row count that didn't match its stated cardinality,
  and some relation symbols differ. I used the PDF throughout.
  [ADD YOUR COUNTS AND ONE EXAMPLE.]
- For 19 urine test-strip codes, the SHIP side gives the scale as `Qn`,
  while LOINC defines the chosen codes as `SemiQn`.
- `ba_pct_e` gives its scale as `Blood`, which is a specimen. I entered it
  as `Qn`.

## Limitations

Specimen, time and scale come from the SHIP side of the published mapping.
They stand in for what a study knows from its lab documentation. For
coagulation tests (platelet-poor plasma) and red-cell indices, they're
closer to expert input than to raw study knowledge.

I corrected two rules after checking them against the reference: serum now
includes `Ser/Plas/Bld`, and `Qn` accepts `SemiQn`. Both follow general
principles, but the reference is what exposed them.

The test covers 72 variables from one dictionary, with one model and one
LOINC version, and I transcribed the answer key by hand. Grading counts any
one of an expert's codes as right, which is lenient for the 39 complex
mappings.

Automated terminology mapping has been studied before. This project
measures one approach against this particular reference.

## Next steps

- Find more candidates: synonym lists, synonyms suggested by the model, or
  longer lists.
- Try a larger model on the variables where rules and model disagree.
- Take specimen and method from the study's own lab documentation.

## How to run

1. Install R, RStudio and Ollama, then `ollama pull qwen2.5:7b`
2. Download `Loinc.csv` from loinc.org into `data-raw/`
3. `install.packages(c("readr","dplyr","stringr","stringdist","httr2"))`
4. Run `scripts/01_prepare.R` to `07_grade.R` in order. Scripts 02 and 06
   call the model once and refuse to run again while their output exists,
   so the results can't change by accident.

Earlier versions of the pipeline are in the repository's commit history.

I usually write my own R code. Because of time pressure, I wrote some part of the code
for this project with help from an AI assistant (Claude). All data used here
is public (the published Zenodo mapping and the LOINC catalogue); no
participant data or confidential material was shared. I conceptualized the
project, made the design decisions, checked every result against the
reference and wrote the interpretation. This was an attempt to explore utility of
LLMs in FAIRIFICATION of the data. It has no scientific use or purpose beyond education.
