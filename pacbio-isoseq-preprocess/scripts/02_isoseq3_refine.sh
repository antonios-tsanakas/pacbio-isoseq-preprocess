#!/usr/bin/env bash
# 02_isoseq3_refine.sh
#
# Extract FLNC reads (full-length non-chimeric, poly-A filtered) for each sample.
# Input:  per-sample FL BAMs from lima + barcode FASTA
# Output: per-sample FLNC BAMs in OUT_DIR
#
# Usage:
#   bash 02_isoseq3_refine.sh \
#     --fl-dir   /data/lima_out \
#     --barcodes /data/Barcodes.fasta \
#     --out      /data/isoseq_refine

set -euo pipefail

FL_DIR=""
BARCODES=""
OUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --fl-dir)   FL_DIR="$2";   shift 2 ;;
        --barcodes) BARCODES="$2"; shift 2 ;;
        --out)      OUT_DIR="$2";  shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "$FL_DIR" || -z "$BARCODES" || -z "$OUT_DIR" ]] && \
    echo "Usage: $0 --fl-dir <lima_out> --barcodes <barcodes.fasta> --out <out_dir>" && exit 1

mkdir -p "${OUT_DIR}"

FL_BAMS=("${FL_DIR}"/*.fl.*.bam)
[[ ${#FL_BAMS[@]} -eq 0 || ! -f "${FL_BAMS[0]}" ]] && \
    echo "[ERROR] No FL BAMs found in ${FL_DIR}" && exit 1

for FL_BAM in "${FL_BAMS[@]}"; do
    # Extract sample name from filename: *.fl.bc1001_5p--bc1001_3p.bam -> bc1001
    SAMPLE=$(basename "${FL_BAM}" | sed 's/.*\.fl\.\(.*\)_5p--.*_3p\.bam/\1/')
    FLNC_BAM="${OUT_DIR}/${SAMPLE}.flnc.bam"

    if [[ -f "${FLNC_BAM}" ]]; then
        echo "[refine] SKIP ${SAMPLE} (output exists)"
        continue
    fi

    echo "[refine] ${SAMPLE}: ${FL_BAM} -> ${FLNC_BAM}"
    isoseq3 refine \
        "${FL_BAM}" \
        "${BARCODES}" \
        "${FLNC_BAM}" \
        --require-polya
    echo "[refine] ${SAMPLE}: DONE ($(samtools flagstat "${FLNC_BAM}" | grep "in total" | cut -d' ' -f1) reads)"
done

echo ""
echo "[refine] All samples done. FLNC BAMs in ${OUT_DIR}:"
ls "${OUT_DIR}"/*.flnc.bam
