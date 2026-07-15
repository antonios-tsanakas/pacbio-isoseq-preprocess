#!/usr/bin/env bash
# run_all.sh
#
# End-to-end PacBio IsoSeq preprocessing: CCS BAM -> coord-sorted BAMs.
#
# Usage:
#   bash run_all.sh \
#     --ccs      /data/project.ccs.bam \
#     --barcodes /data/Barcodes.fasta \
#     --genome   /data/refs/genome.fa \
#     --out      /data/output \
#     --threads  8
#
# Outputs per sample (in --out/aligned/):
#   <sample>.flnc.minimap2.bam
#   <sample>.flnc.minimap2.bam.bai

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CCS=""
BARCODES=""
GENOME=""
OUT_DIR=""
THREADS=8

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ccs)      CCS="$2";      shift 2 ;;
        --barcodes) BARCODES="$2"; shift 2 ;;
        --genome)   GENOME="$2";   shift 2 ;;
        --out)      OUT_DIR="$2";  shift 2 ;;
        --threads)  THREADS="$2";  shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "$CCS" || -z "$BARCODES" || -z "$GENOME" || -z "$OUT_DIR" ]] && {
    echo "Usage: $0 --ccs <ccs.bam> --barcodes <barcodes.fasta> --genome <genome.fa> --out <out_dir> [--threads N]"
    exit 1
}

LIMA_DIR="${OUT_DIR}/lima"
REFINE_DIR="${OUT_DIR}/isoseq_refine"
ALIGNED_DIR="${OUT_DIR}/aligned"

echo "════════════════════════════════════════════"
echo "  Step 1/3: Lima demultiplexing"
echo "════════════════════════════════════════════"
bash "${SCRIPT_DIR}/01_demux_lima.sh" \
    --ccs      "${CCS}" \
    --barcodes "${BARCODES}" \
    --out      "${LIMA_DIR}"

echo ""
echo "════════════════════════════════════════════"
echo "  Step 2/3: isoseq3 refine (FLNC)"
echo "════════════════════════════════════════════"
bash "${SCRIPT_DIR}/02_isoseq3_refine.sh" \
    --fl-dir   "${LIMA_DIR}" \
    --barcodes "${BARCODES}" \
    --out      "${REFINE_DIR}"

echo ""
echo "════════════════════════════════════════════"
echo "  Step 3/3: minimap2 alignment"
echo "════════════════════════════════════════════"
bash "${SCRIPT_DIR}/03_align_minimap2.sh" \
    --flnc-dir "${REFINE_DIR}" \
    --genome   "${GENOME}" \
    --out      "${ALIGNED_DIR}" \
    --threads  "${THREADS}"

echo ""
echo "════════════════════════════════════════════"
echo "  COMPLETE"
echo "════════════════════════════════════════════"
echo "Coord-sorted BAMs ready in: ${ALIGNED_DIR}"
