# Where these files come from

## From Zenodo, unchanged

Inau ET, Radke D, Westphal S, Schäfer C, Zeleke AA, Nauck M, Schmidt CO,
Waltemath D. Semantic Enrichment of the Laboratory Data Dictionary of the
Study of Health in Pomerania (SHIP-START-4) with LOINC; Detailed Mapping
Results. Zenodo. https://zenodo.org/records/15711189
Licence: CC BY 4.0

- `SHIP_START-4.pdf`
- `LOINC_simple2025.csv`, `LOINC_complex2025.csv`,
  `LOINC_successful2025.csv`, `LOINC_unsuccessful2025.csv`

## Made in this project from that PDF

These are derived from CC BY 4.0 material, so the same licence applies.

- `answer_key.csv`: Tables 3 to 5 as one table, one row per variable and
  LOINC code. Where the CSVs and the PDF disagree, I followed the PDF.
- `ship_specimen.csv`: the S (system) line from the SHIP side, plus a
  normalised specimen group.
- `ship_axes.csv`: the T (time), Sc (scale) and P (unit) lines from the
  SHIP side. The PDF gives `ba_pct_e` a scale of "Blood"; I entered `Qn`.

## Not included

`Loinc.csv`, LOINC release [VERSION], from https://loinc.org/downloads/.
It's free with registration, but the licence doesn't allow redistribution,
so you need to download it yourself.
