# DIA-NN 2.2.0 on Northwestern QUEST

A guide for running DIA-NN proteomics searches on Northwestern's QUEST HPC cluster.

## Overview

This workflow consists of two steps:
1. **Library Generation** (`Lib_Gen.sh`) - Creates a predicted spectral library from FASTA files
2. **DIA Search** (`DIA_search.sh`) - Searches DIA raw files against the generated library

## Prerequisites

### Required Files

Before running the scripts, ensure you have:

- **FASTA files:**
  - Target proteome FASTA (e.g., `Mouse_uniprotkb_proteome_UP000000589_2025_10_16.fasta`)
  - Contaminant FASTA (e.g., `camprotR_240512_cRAP_20190401_full_tags.fasta`)

- **Raw files** (for search step):
  - DIA-MS raw files (e.g., `Gel_EDTA_DIA.raw`, `Gel_NO_DIA.raw`)

### QUEST Allocation

Update the `#SBATCH --account` and `#SBATCH --partition` lines in both scripts with your allocation (e.g., `b1028`).

## Step 1: Generate Predicted Library

### Script: `Lib_Gen.sh`

This script generates a predicted spectral library from your FASTA files without requiring experimental data.

**Key parameters:**
- **CPUs:** 24 cores
- **Memory:** 64 GB
- **Time:** 3 hours
- **Output:** `mouse_lib.parquet` (predicted spectral library)

### Customization

Edit these variables in the script:
```bash
CONTAM_FASTA="./camprotR_240512_cRAP_20190401_full_tags.fasta"
TARGET_FASTA="./Mouse_uniprotkb_proteome_UP000000589_2025_10_16.fasta"
OUT_LIB="./mouse_lib.parquet"
```

### Submission

```bash
sbatch Lib_Gen.sh
```

### Monitor Progress

```bash
# Check job status
squeue -u $USER

# View output log
tail -f diann_pred_lib_<job_id>.out

# Check for errors
tail -f diann_pred_lib_<job_id>.err
```

## Step 2: Search DIA Data

### Script: `DIA_search.sh`

This script searches your DIA raw files against the predicted library generated in Step 1.

**Key parameters:**
- **CPUs:** 36 cores
- **Memory:** 64 GB
- **Time:** 3 hours
- **Output:** `mouse_search_report.parquet` (search results and quantification)

### Customization

Edit these variables in the script:
```bash
RAW1="./Gel_EDTA_DIA.raw"
RAW2="./Gel_NO_DIA.raw"
LIB="./mouse_lib.parquet"  # Must match output from Lib_Gen.sh
FASTA_MOUSE="./Mouse_uniprotkb_proteome_UP000000589_2025_10_16.fasta"
FASTA_CONTAM="./camprotR_240512_cRAP_20190401_full_tags.fasta"
OUT_REPORT="./mouse_search_report.parquet"
```

**To add more raw files:**
```bash
--f "${RAW1}" \
--f "${RAW2}" \
--f "${RAW3}" \  # Add additional files
```

### Submission

```bash
sbatch DIA_search.sh
```

## Understanding Key DIA-NN Parameters

### Library Generation

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--gen-spec-lib` | - | Generate spectral library from FASTA |
| `--predictor` | - | Use deep learning predictor |
| `--min-pep-len` | 7 | Minimum peptide length |
| `--max-pep-len` | 30 | Maximum peptide length |
| `--min-pr-charge` | 1 | Minimum precursor charge |
| `--max-pr-charge` | 4 | Maximum precursor charge |
| `--cut` | K*,R* | Trypsin cleavage sites |
| `--missed-cleavages` | 1 | Allow 1 missed cleavage |
| `--unimod4` | - | Include common modifications |

### DIA Search

| Parameter | Value | Description |
|-----------|-------|-------------|
| `--qvalue` | 0.01 | 1% FDR threshold |
| `--matrices` | - | Generate protein/gene matrices |
| `--var-mods` | 2 | Maximum 2 variable mods per peptide |
| `--var-mod` | UniMod:35 | Oxidation of methionine |
| `--var-mod` | UniMod:1 | N-terminal acetylation |
| `--window` | 30 | Extraction window (ppm) |
| `--mass-acc` | 20 | MS2 mass accuracy (ppm) |
| `--mass-acc-ms1` | 10 | MS1 mass accuracy (ppm) |
| `--peptidoforms` | - | Report peptidoforms separately |
| `--cont-quant-exclude` | cRAP- | Exclude contaminants from quantification |

## Output Files

### Library Generation
- `mouse_lib.parquet` - Predicted spectral library (used in Step 2)
- `test_report.parquet` - Library generation report

### DIA Search
- `mouse_search_report.parquet` - Main output with peptide/protein identifications and quantification
- `mouse_search_report.pg_matrix.tsv` - Protein group quantification matrix
- `mouse_search_report.pr_matrix.tsv` - Precursor quantification matrix (if requested)
- `mouse_search_report.stats.tsv` - Search statistics

### Reading Results

The `.parquet` files can be read in:
- **R:** `arrow::read_parquet()` or `diann` R package
- **Python:** `pandas.read_parquet()`
- **Excel:** Convert using command-line tools or scripts

## Troubleshooting

### "No such file or directory" Error

**Problem:** `slurmstepd: error: execve(): diann: No such file or directory`

**Solution:** Don't use `srun` wrapper. Call `diann` directly as shown in the provided scripts.

### Library Filename Mismatch

**Problem:** Search can't find library file

**Solution:** Ensure `OUT_LIB` in `Lib_Gen.sh` matches `LIB` in `DIA_search.sh`:
```bash
# In Lib_Gen.sh
OUT_LIB="./mouse_lib.parquet"

# In DIA_search.sh
LIB="./mouse_lib.parquet"  # Must match!
```

### Out of Memory

**Problem:** Job killed due to insufficient memory

**Solution:** Increase memory allocation:
```bash
#SBATCH --mem=128G  # or higher
```

### Job Timeout

**Problem:** Job exceeds time limit

**Solution:** Increase time or reduce data complexity:
```bash
#SBATCH --time=06:00:00  # 6 hours
```

## Best Practices

1. **Test with subset** - Start with 1-2 raw files to verify setup
2. **Check file sizes** - Ensure all input files exist and are not empty (the scripts include sanity checks)
3. **Module availability** - Verify DIA-NN module loads correctly: `module avail diann`
4. **Consistent naming** - Keep library filenames consistent between steps
5. **Resource monitoring** - Check memory/CPU usage with `seff <job_id>` after completion

## Example Workflow

```bash
# 1. Prepare files in working directory
cd /path/to/your/project
ls -lh *.fasta *.raw

# 2. Generate library
sbatch Lib_Gen.sh

# 3. Wait for completion, check output
squeue -u $USER
cat diann_pred_lib_*.out

# 4. Verify library was created
ls -lh mouse_lib.parquet

# 5. Run search
sbatch DIA_search.sh

# 6. Monitor and retrieve results
tail -f diann_search_*.out
```

## Getting Help

- **DIA-NN Documentation:** https://github.com/vdemichev/DiaNN
- **QUEST Support:** quest-help@northwestern.edu
- **Check job details:** `seff <job_id>`
- **View queue:** `squeue -u $USER`

## Citation

If you use DIA-NN in your research, please cite:
> Demichev V, Messner CB, Vernardis SI, Lilley KS, Ralser M. DIA-NN: neural networks and interference correction enable deep proteome coverage in high throughput. Nat Methods. 2020;17(1):41-44.

---

**Version:** DIA-NN 2.2.0  
**Last Updated:** October 2025
