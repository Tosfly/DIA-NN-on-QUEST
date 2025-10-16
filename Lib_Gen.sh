#!/bin/bash
#SBATCH --job-name=diann_pred_lib
#SBATCH --account=b1028          # <-- change to your Quest allocation (e.g., b1028)
#SBATCH --partition=b1028         # <-- change to your partition (e.g., b1028)
#SBATCH --time=03:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=24
#SBATCH --mem=64G
#SBATCH --output=diann_pred_lib_%j.out
#SBATCH --error=diann_pred_lib_%j.err
## #SBATCH --mail-type=BEGIN,END,FAIL
## #SBATCH --mail-user=you@northwestern.edu  # optional

set -euo pipefail

echo "Started on: $(hostname) at $(date)"
echo "Cores: ${SLURM_CPUS_PER_TASK}"
cd "$SLURM_SUBMIT_DIR"

# Load DIA-NN 2.2.0 (use your site module; if your module is named differently, adjust)
module purge
module load diann

# Inputs (edit paths if needed)
CONTAM_FASTA="./camprotR_240512_cRAP_20190401_full_tags.fasta"
TARGET_FASTA="./Mouse_uniprotkb_proteome_UP000000589_2025_10_16.fasta"

# Outputs
REPORT="./test_report.parquet"
OUT_LIB="./mouse_lib.parquet"   # fixed extension

# Run DIA-NN to generate predicted spectral library from FASTA
diann \
  --lib \
  --verbose 1 \
  --out "${REPORT}" \
  --qvalue 0.01 \
  --out-lib "${OUT_LIB}" \
  --gen-spec-lib \
  --predictor \
  --reannotate \
  --fasta "${CONTAM_FASTA}" \
  --cont-quant-exclude cRAP- \
  --fasta "${TARGET_FASTA}" \
  --fasta-search \
  --min-fr-mz 200 \
  --max-fr-mz 1800 \
  --met-excision \
  --min-pep-len 7 \
  --max-pep-len 30 \
  --min-pr-mz 300 \
  --max-pr-mz 1800 \
  --min-pr-charge 1 \
  --max-pr-charge 4 \
  --cut K*,R* \
  --missed-cleavages 1 \
  --unimod4 \
  --no-prot-inf \
  --reanalyse \
  --rt-profiling \
  --threads "${SLURM_CPUS_PER_TASK}"

status=$?
echo "DIA-NN finished with exit code: ${status} at $(date)"
exit ${status}

