#!/bin/bash
#SBATCH --job-name=diann_search_mouse
#SBATCH --account=b1028
#SBATCH --partition=b1028
#SBATCH --time=03:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=64G
#SBATCH --output=diann_search_%j.out
#SBATCH --error=diann_search_%j.err

set -euo pipefail

echo "Host: $(hostname)"
echo "Start: $(date)"
echo "CPUs: ${SLURM_CPUS_PER_TASK}"
cd "${SLURM_SUBMIT_DIR}"

# ---- Load DIA-NN ----
module purge
module load diann

# ---- Inputs (all in current folder) ----
RAW1="./Gel_EDTA_DIA.raw"
RAW2="./Gel_NO_DIA.raw"
LIB="./mouse_lib.predicted.speclib"  # Fixed: matches the output from Lib_Gen.sh
FASTA_MOUSE="./Mouse_uniprotkb_proteome_UP000000589_2025_10_16.fasta"
FASTA_CONTAM="./camprotR_240512_cRAP_20190401_full_tags.fasta"

# ---- Output ----
OUT_REPORT="./mouse_search_report.parquet"

# ---- Sanity checks ----
for f in "$RAW1" "$RAW2" "$LIB" "$FASTA_MOUSE" "$FASTA_CONTAM"; do
  [[ -s "$f" ]] || { echo "Missing or empty: $f"; exit 3; }
done

export OMP_NUM_THREADS="${SLURM_CPUS_PER_TASK}"

echo "DIA-NN search start: $(date)"

# Fixed: Call diann directly without srun, just like Lib_Gen.sh
diann \
  --f "${RAW1}" \
  --f "${RAW2}" \
  --lib "${LIB}" \
  --threads "${SLURM_CPUS_PER_TASK}" \
  --verbose 1 \
  --out "${OUT_REPORT}" \
  --qvalue 0.01 \
  --matrices \
  --reannotate \
  --fasta "${FASTA_CONTAM}" \
  --cont-quant-exclude cRAP- \
  --fasta "${FASTA_MOUSE}" \
  --met-excision \
  --min-pep-len 6 \
  --max-pep-len 30 \
  --min-pr-mz 300 \
  --max-pr-mz 1800 \
  --min-pr-charge 1 \
  --max-pr-charge 4 \
  --cut K*,R* \
  --missed-cleavages 1 \
  --unimod4 \
  --var-mods 2 \
  --var-mod UniMod:35,15.994915,M \
  --var-mod UniMod:1,42.010565,*n \
  --window 30 \
  --mass-acc 20 \
  --mass-acc-ms1 10 \
  --individual-mass-acc \
  --individual-windows \
  --peptidoforms \
  --reanalyse \
  --rt-profiling

status=$?
echo "DIA-NN finished with exit code: ${status} at $(date)"
exit ${status}
