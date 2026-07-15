#!/usr/bin/env bash
# 03_align_minimap2.sh
#
# Align FLNC reads to the reference genome and produce a coordinate-sorted BAM.
# Output BAMs are the direct input to OmniFuse (or any other downstream tool).
#
# Usage:
#   bash 03_align_minimap2.sh \
#     --flnc-dir /data/isoseq_refine \
#     --genome   /data/refs/genome.fa \
#     --out      /data/aligned \
#     --threads  8

set -euo pipefail

FLNC_DIR=""
GENOME=""
OUT_DIR=""
THREADS=8

while [[ $# -gt 0 ]]; do
    case "$1" in
        --flnc-dir) FLNC_DIR="$2"; shift 2 ;;
        --genome)   GENOME="$2";   shift 2 ;;
        --out)      OUT_DIR="$2";  shift 2 ;;
        --threads)  THREADS="$2";  shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "$FLNC_DIR" || -z "$GENOME" || -z "$OUT_DIR" ]] && \
    echo "Usage: $0 --flnc-dir <flnc_dir> --genome <genome.fa> --out <out_dir> [--threads N]" && exit 1

[[ ! -f "$GENOME" ]] && echo "[ERROR] Genome FASTA not found: ${GENOME}" && exit 1

mkdir -p "${OUT_DIR}"

FLNC_BAMS=("${FLNC_DIR}"/*.flnc.bam)
[[ ${#FLNC_BAMS[@]} -eq 0 || ! -f "${FLNC_BAMS[0]}" ]] && \
    echo "[ERROR] No FLNC BAMs found in ${FLNC_DIR}" && exit 1

for FLNC_BAM in "${FLNC_BAMS[@]}"; do
    SAMPLE=$(basename "${FLNC_BAM}" .flnc.bam)
    OUT_BAM="${OUT_DIR}/${SAMPLE}.flnc.minimap2.bam"

    if [[ -f "${OUT_BAM}" && -f "${OUT_BAM}.bai" ]]; then
        echo "[align] SKIP ${SAMPLE} (output exists)"
        continue
    fi

    echo "[align] ${SAMPLE}: aligning -> ${OUT_BAM}"
    samtools fastq -@ "${THREADS}" "${FLNC_BAM}" \
        | minimap2 \
            -t "${THREADS}" \
            -ax splice:hq \
            -uf \
            --secondary=no \
            "${GENOME}" \
            - \
        | samtools sort -@ "${THREADS}" -o "${OUT_BAM}"

    echo "[align] ${SAMPLE}: indexing..."
    samtools index "${OUT_BAM}"
    echo "[align] ${SAMPLE}: DONE"
done

echo ""
echo "[align] All samples done. Coord-sorted BAMs in ${OUT_DIR}:"
ls "${OUT_DIR}"/*.flnc.minimap2.bam
echo ""
echo "These BAMs are ready for downstream analysis (e.g. OmniFuse, SQANTI, FLAMES)."
