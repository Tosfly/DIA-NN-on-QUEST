# DIA-NN 2.5.1 phosphoproteomics workflow on Northwestern QUEST

This workflow generates a predicted phosphopeptide spectral library and then searches 16 Thermo DIA RAW files on Northwestern QUEST.

## Final scripts

1. `Lib_Gen_Mouse_Phos.sh`  
   Generates the predicted library from the project-specific target FASTA plus the cRAP contaminant FASTA.
2. `DIA_MS_Phos_search.sh`  
   Searches `Phos_A1.raw`–`Phos_A8.raw` and `Phos_B1.raw`–`Phos_B8.raw` against that predicted library.

Both scripts load:

```bash
module purge
module load diann/2.5.1-linux
```

## Corrections made

The scripts and documentation are now internally consistent:

- DIA-NN version updated from 2.2.0 to **2.5.1**.
- Script names, SLURM job names, log names, allocation, partitions, CPU, memory, and walltimes now match the actual scripts.
- Both scripts use the same project-specific target FASTA:

  ```text
  Mouse_UP000000589_2025_10_16_AD_custom_NLF_PSEN1dE9_humanMAPT.fasta
  ```

- Both scripts use the same default precursor range: **400–1100 m/z**.
- Both scripts use the same default precursor-charge range: **2–3**.
- Both scripts use the same digestion and phosphosite search space: one missed cleavage, up to three variable phosphorylation sites, and phosphorylation on S/T/Y.
- The library basename generated in Step 1 exactly matches the library basename consumed in Step 2.
- The search-script submission example now names the actual corrected search script.
- Output-file annotations now reflect the actual DIA-NN `.predicted.speclib`, `.parquet`, site-report, matrix, manifest, and statistics outputs.
- The cRAP FASTA headers contain the `cRAP-` tag expected by `--cont-quant-exclude cRAP-`.
- `--proteoforms` is documented as the phosphoproteomics scoring mode; variable phosphorylation also activates DIA-NN's peptidoform-confidence calculations.
- `--reanalyse` is documented correctly as enabling DIA-NN match-between-runs processing.

## Default QUEST resources

| Step | Partition | Time | CPUs | Memory | Default log prefix |
|---|---:|---:|---:|---:|---|
| Library generation | `normal` | 24 h | 36 | 128 GB | `diann_AD_phos_lib_<jobid>` |
| DIA search | `long` | 96 h | 36 | 160 GB | `diann_AD_phos_search_<jobid>` |

Both scripts use allocation `p20710`.

## Required project files

Place these files in the project directory unless using the directory overrides described below.

### FASTA files

```text
Mouse_UP000000589_2025_10_16_AD_custom_NLF_PSEN1dE9_humanMAPT.fasta
camprotR_240512_cRAP_20190401_full_tags.fasta
```

### DIA RAW files

```text
Phos_A1.raw  Phos_A2.raw  Phos_A3.raw  Phos_A4.raw
Phos_A5.raw  Phos_A6.raw  Phos_A7.raw  Phos_A8.raw
Phos_B1.raw  Phos_B2.raw  Phos_B3.raw  Phos_B4.raw
Phos_B5.raw  Phos_B6.raw  Phos_B7.raw  Phos_B8.raw
```

### Scripts

```text
Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

## Recommended directory layout

```text
/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos/
├── Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
├── DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
├── Mouse_UP000000589_2025_10_16_AD_custom_NLF_PSEN1dE9_humanMAPT.fasta
├── camprotR_240512_cRAP_20190401_full_tags.fasta
├── Phos_A1.raw
├── ...
└── Phos_B8.raw
```

Make the scripts executable:

```bash
chmod +x \
  Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh \
  DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

## Step 0: preflight checks

```bash
cd /projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos

bash -n Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
bash -n DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh

module purge
module load diann/2.5.1-linux
command -v diann
diann --about

ls -lh \
  Mouse_UP000000589_2025_10_16_AD_custom_NLF_PSEN1dE9_humanMAPT.fasta \
  camprotR_240512_cRAP_20190401_full_tags.fasta \
  Phos_A{1..8}.raw \
  Phos_B{1..8}.raw
```

The `ls` command must return all 18 biological input files as non-empty files.

## Step 1: generate the predicted phosphopeptide library

From the project directory:

```bash
sbatch Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
```

Equivalent explicit submission:

```bash
WORKDIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos \
MIN_PR_MZ=400 \
MAX_PR_MZ=1100 \
sbatch Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
```

### Expected default library

```text
Mouse_AD_NLF_PSEN1dE9_humanMAPT_Phos_DIA400_1100_predict.predicted.speclib
```

The `.predicted.speclib` extension is expected: the `.parquet` value supplied to `--out-lib` is a naming template for predicted-library generation.

### Monitor and verify

```bash
squeue -u "$USER"
tail -f diann_AD_phos_lib_<jobid>.out
tail -f diann_AD_phos_lib_<jobid>.err

seff <jobid>
ls -lh Mouse_AD_NLF_PSEN1dE9_humanMAPT_Phos_DIA400_1100_predict.predicted.speclib
```

Do not submit the search until the predicted library exists and is non-empty.

## Step 2: search the 16 DIA RAW files

```bash
sbatch DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

Equivalent explicit submission:

```bash
WORKDIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos \
MIN_PR_MZ=400 \
MAX_PR_MZ=1100 \
sbatch DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

### Expected main report

```text
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.parquet
```

### Monitor and verify

```bash
squeue -u "$USER"
tail -f diann_AD_phos_search_<jobid>.out
tail -f diann_AD_phos_search_<jobid>.err

seff <jobid>
ls -lh Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.parquet
```

## Critical naming contract

The library-generation and search submissions must use the same values for:

```text
TARGET_FASTA_NAME
LIB_PREFIX
MIN_PR_MZ
MAX_PR_MZ
MIN_PR_CHARGE
MAX_PR_CHARGE
```

With the defaults, the library script creates:

```text
Mouse_AD_NLF_PSEN1dE9_humanMAPT_Phos_DIA400_1100_predict.predicted.speclib
```

and the search script requests that exact file.

For a different DIA isolation range, pass the same range to both jobs. Example:

```bash
MIN_PR_MZ=350 MAX_PR_MZ=1650 \
sbatch Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh

MIN_PR_MZ=350 MAX_PR_MZ=1650 \
sbatch DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

Do not generate a `400_1100` library and submit a search configured for `350_1650`; the search will correctly stop because the expected library filename will not exist.

## Directory overrides

The scripts support separate directories without editing the files.

| Variable | Purpose | Default |
|---|---|---|
| `WORKDIR` | RAW-file and execution directory | SLURM submission directory |
| `FASTA_DIR` | Target and contaminant FASTA directory | `WORKDIR` |
| `LIB_DIR` | Predicted-library directory; search script only | `WORKDIR` |
| `OUT_DIR` | Output directory | `WORKDIR` |

Example:

```bash
WORKDIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos/raw \
FASTA_DIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos/fasta \
LIB_DIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos/library \
OUT_DIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos/results \
sbatch DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

## Overwriting prior outputs

The default is protective: the scripts stop rather than overwrite an existing main output.

To deliberately replace the outputs generated from the same report/library prefix:

```bash
OVERWRITE=1 sbatch Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
```

or:

```bash
OVERWRITE=1 sbatch DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh
```

Use `OVERWRITE=1` only after confirming that the prior results are expendable.

## Main DIA-NN settings

### Shared FASTA-digest and library settings

| Option | Default | Meaning |
|---|---:|---|
| `--cut 'K*,R*,!*P'` | tryptic | Cleaves after K/R except before P |
| `--missed-cleavages` | 1 | Maximum missed cleavages |
| `--min-pep-len` | 5 | Minimum peptide length |
| `--max-pep-len` | 30 | Maximum peptide length |
| `--min-pr-mz` / `--max-pr-mz` | 400 / 1100 | Precursor range matched to the DIA method |
| `--min-pr-charge` / `--max-pr-charge` | 2 / 3 | Phosphopeptide precursor-charge range |
| `--unimod4` | enabled | Fixed carbamidomethylation of cysteine, UniMod:4 |
| `--var-mods` | 3 | Maximum occupied variable-modification sites per peptide |
| `--var-mod 'UniMod:21,79.966331,STY'` | enabled | Phosphorylation on S, T, or Y |
| `--met-excision` | enabled | Variable protein N-terminal methionine excision |

### Search-only settings

| Option | Value | Meaning |
|---|---:|---|
| `--qvalue` | 0.01 | Main-report precursor q-value threshold |
| `--reannotate` | enabled | Reannotates library precursors using the supplied FASTA files |
| `--matrices` | enabled | Produces quantitative matrices and a manifest |
| `--proteoforms` | enabled | Proteoform scoring mode recommended by DIA-NN for typical phosphoproteomics |
| `--reanalyse` | enabled | Enables DIA-NN match-between-runs processing |
| `--individual-mass-acc` | enabled | Optimizes automatic mass accuracy independently by run |
| `--individual-windows` | enabled | Optimizes the automatic scan window independently by run |
| `--matrix-spec-q` | 0.01 | Adds a 1% run-specific protein q-value filter to protein matrices |
| `--cont-quant-exclude cRAP-` | enabled | Excludes tagged contaminants from normalization and contaminant-free protein quantification |

## Expected search outputs

DIA-NN derives auxiliary filenames from the main report stem. Depending on the data and enabled output modes, expect files including:

```text
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.parquet
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.site_report.parquet
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.pg_matrix.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.gg_matrix.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.unique_genes_matrix.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.pr_matrix.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.protein_description.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.stats.tsv
Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.manifest.txt
```

The `.site_report.parquet` file is the preferred detailed phosphosite output because it retains localisation and precursor-level information. The site matrices are convenient summaries but are more heavily processed.

## Reading `.parquet` results

### Python

```python
import pandas as pd

report = pd.read_parquet(
    "Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.parquet"
)
print(report.shape)
print(report.columns.tolist())
```

A parquet engine such as `pyarrow` must be installed.

### R

```r
library(arrow)

report <- read_parquet(
  "Human_Tau_NLF_PS1_DIA_Phos_DIA400_1100_auto_search_report.parquet"
)
print(dim(report))
```

## Troubleshooting

### Missing predicted library

Check the exact range-encoded filename:

```bash
ls -lh Mouse_AD_NLF_PSEN1dE9_humanMAPT_Phos_DIA*_predict.predicted.speclib
```

Then confirm that Step 1 and Step 2 used identical `MIN_PR_MZ` and `MAX_PR_MZ` values.

### Missing or empty input

Both scripts stop before starting DIA-NN when any required FASTA, RAW file, or library is absent or zero bytes. Read the exact path printed after:

```text
ERROR: missing or empty input:
```

### `diann: command not found`

```bash
module purge
module load diann/2.5.1-linux
command -v diann
diann --about
```

If `command -v diann` returns nothing, capture the module output and contact QUEST support.

### Existing output blocks submission

This is deliberate. Rename or archive the prior output, or submit with `OVERWRITE=1` after checking it.

### Search uses excessive memory or time

First confirm that the precursor range is no wider than the MS2 isolation range of the acquisition method. A wider predicted library unnecessarily expands the search space. Also confirm that the search remains at three variable phosphorylation sites and one missed cleavage unless there is a specific experimental reason to expand it.

### Inspect the job after completion

```bash
seff <jobid>
sacct -j <jobid> --format=JobID,State,Elapsed,MaxRSS,AllocCPUS,ExitCode
```

## Official DIA-NN documentation

- DIA-NN repository and current documentation: <https://github.com/vdemichev/DiaNN>
- Command-line reference: see the **Command-line reference** section in the repository README.
- PTM guidance: see **PTMs and peptidoforms** in the repository README.

## Citation

Demichev V, Messner CB, Vernardis SI, Lilley KS, Ralser M. DIA-NN: neural networks and interference correction enable deep proteome coverage in high throughput. *Nature Methods*. 2020;17:41–44.

---

**Workflow version:** DIA-NN 2.5.1 corrected QUEST workflow  
**Updated:** July 25, 2026
