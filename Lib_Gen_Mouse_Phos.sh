#!/bin/bash
#SBATCH --job-name=diann_AD_phos_lib
#SBATCH --account=p20710
#SBATCH --partition=normal
#SBATCH --time=24:00:00
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=36
#SBATCH --mem=128G
#SBATCH --output=diann_AD_phos_lib_%j.out
#SBATCH --error=diann_AD_phos_lib_%j.err

set -Eeuo pipefail
trap 'rc=$?; echo "ERROR: command failed at line ${LINENO} with exit code ${rc}" >&2; exit "${rc}"' ERR

# Generate the predicted phosphopeptide library used by
# DIA_MS_Phos_search_DIA-NN2.5.1_auto_corrected.sh.
#
# Submit from the project folder containing the target and cRAP FASTA files,
# or override WORKDIR, FASTA_DIR, and OUT_DIR at submission. Example:
#   WORKDIR=/projects/p20710/ywd617/Human_Tau_NLF_PS1_DIA_Phos \
#   sbatch Lib_Gen_Mouse_Phos_DIA-NN2.5.1_auto_corrected.sh
SUBMIT_DIR="${SLURM_SUBMIT_DIR:-${PWD}}"
WORKDIR="${WORKDIR:-${SUBMIT_DIR}}"
FASTA_DIR="${FASTA_DIR:-${WORKDIR}}"
OUT_DIR="${OUT_DIR:-${WORKDIR}}"
THREADS="${SLURM_CPUS_PER_TASK:-36}"

cd "${WORKDIR}"
mkdir -p "${OUT_DIR}"

module purge
module load diann/2.5.1-linux

# These defaults must match the FASTA and library basename used by the search script.
TARGET_FASTA_NAME="${TARGET_FASTA_NAME:-Mouse_UP000000589_2025_10_16_AD_custom_NLF_PSEN1dE9_humanMAPT.fasta}"
CONTAM_FASTA_NAME="${CONTAM_FASTA_NAME:-camprotR_240512_cRAP_20190401_full_tags.fasta}"
LIB_PREFIX="${LIB_PREFIX:-Mouse_AD_NLF_PSEN1dE9_humanMAPT_Phos}"

TARGET_FASTA="${FASTA_DIR}/${TARGET_FASTA_NAME}"
CONTAM_FASTA="${FASTA_DIR}/${CONTAM_FASTA_NAME}"

# Match the precursor m/z range to the DIA method's MS2 isolation range.
# Use the same values when submitting the search script because the range is
# encoded in the predicted-library filename.
MIN_PR_MZ="${MIN_PR_MZ:-400}"
MAX_PR_MZ="${MAX_PR_MZ:-1100}"
MIN_FR_MZ="${MIN_FR_MZ:-145}"
MAX_FR_MZ="${MAX_FR_MZ:-1450}"

# DIA-NN's current phosphoproteomics guidance recommends precursor charges 2-3,
# no more than three variable phosphorylation sites, and one missed cleavage.
MIN_PR_CHARGE="${MIN_PR_CHARGE:-2}"
MAX_PR_CHARGE="${MAX_PR_CHARGE:-4}"
MIN_PEP_LEN="${MIN_PEP_LEN:-5}"
MAX_PEP_LEN="${MAX_PEP_LEN:-30}"
MAX_VAR_MODS="${MAX_VAR_MODS:-3}"
MISSED_CLEAVAGES="${MISSED_CLEAVAGES:-1}"

REPORT="${OUT_DIR}/${LIB_PREFIX}_DIA${MIN_PR_MZ}_${MAX_PR_MZ}_libGen_report.parquet"
OUT_LIB_TEMPLATE="${OUT_DIR}/${LIB_PREFIX}_DIA${MIN_PR_MZ}_${MAX_PR_MZ}_predict.parquet"
EXPECTED_LIB="${OUT_LIB_TEMPLATE%.parquet}.predicted.speclib"

for f in "${CONTAM_FASTA}" "${TARGET_FASTA}"; do
  [[ -s "${f}" ]] || { echo "ERROR: missing or empty input: ${f}" >&2; exit 3; }
done

OVERWRITE="${OVERWRITE:-0}"
if [[ "${OVERWRITE}" != "0" && "${OVERWRITE}" != "1" ]]; then
  echo "ERROR: OVERWRITE must be 0 or 1; received: ${OVERWRITE}" >&2
  exit 3
fi

if [[ "${OVERWRITE}" != "1" ]] && \
   { [[ -e "${EXPECTED_LIB}" ]] || [[ -e "${REPORT}" ]] || [[ -e "${OUT_LIB_TEMPLATE}" ]]; }; then
  echo "ERROR: one or more library-generation outputs already exist:" >&2
  printf '  %s\n' "${EXPECTED_LIB}" "${REPORT}" "${OUT_LIB_TEMPLATE}" >&2
  echo "Move/delete the existing outputs, or resubmit with OVERWRITE=1." >&2
  exit 3
fi

if [[ "${OVERWRITE}" == "1" ]]; then
  rm -f -- \
    "${EXPECTED_LIB}" \
    "${REPORT}" \
    "${OUT_LIB_TEMPLATE}" \
    "${OUT_LIB_TEMPLATE%.parquet}.log.txt"
fi

export OMP_NUM_THREADS="${THREADS}"

echo "Host: $(hostname)"
echo "Start: $(date)"
echo "Work directory: ${WORKDIR}"
echo "FASTA directory: ${FASTA_DIR}"
echo "Output directory: ${OUT_DIR}"
echo "Threads: ${THREADS}"
echo "Target FASTA: ${TARGET_FASTA}"
echo "Contaminant FASTA: ${CONTAM_FASTA}"
echo "Precursor m/z range: ${MIN_PR_MZ}-${MAX_PR_MZ}"
echo "Fragment m/z range: ${MIN_FR_MZ}-${MAX_FR_MZ}"
echo "Precursor charge range: ${MIN_PR_CHARGE}-${MAX_PR_CHARGE}"
echo "Expected predicted library: ${EXPECTED_LIB}"
echo "DIA-NN phosphopeptide-library generation start: $(date)"

diann \
  --verbose 1 \
  --out "${REPORT}" \
  --qvalue 0.01 \
  --out-lib "${OUT_LIB_TEMPLATE}" \
  --gen-spec-lib \
  --predictor \
  --fasta "${CONTAM_FASTA}" \
  --cont-quant-exclude cRAP- \
  --fasta "${TARGET_FASTA}" \
  --fasta-search \
  --min-fr-mz "${MIN_FR_MZ}" \
  --max-fr-mz "${MAX_FR_MZ}" \
  --met-excision \
  --min-pep-len "${MIN_PEP_LEN}" \
  --max-pep-len "${MAX_PEP_LEN}" \
  --min-pr-mz "${MIN_PR_MZ}" \
  --max-pr-mz "${MAX_PR_MZ}" \
  --min-pr-charge "${MIN_PR_CHARGE}" \
  --max-pr-charge "${MAX_PR_CHARGE}" \
  --cut 'K*,R*,!*P' \
  --missed-cleavages "${MISSED_CLEAVAGES}" \
  --unimod4 \
  --var-mods "${MAX_VAR_MODS}" \
  --var-mod 'UniMod:21,79.966331,STY' \
  --no-prot-inf \
  --threads "${THREADS}"

[[ -s "${EXPECTED_LIB}" ]] || {
  echo "ERROR: expected predicted library was not found: ${EXPECTED_LIB}" >&2
  echo "Candidate DIA-NN outputs:" >&2
  find "${OUT_DIR}" -maxdepth 1 -type f \
    \( -name '*.speclib' -o -name '*.parquet' -o -name '*.log.txt' \) \
    -printf '  %p\n' 2>/dev/null || true
  exit 4
}

ls -lh "${EXPECTED_LIB}"
if [[ -s "${REPORT}" ]]; then
  ls -lh "${REPORT}"
else
  echo "Note: DIA-NN did not create a non-empty library-generation main report; the predicted library was created successfully."
fi

echo "Completed: $(date)"
