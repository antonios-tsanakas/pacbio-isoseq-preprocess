#!/usr/bin/env bash
# 01_demux_lima.sh
#
# Demultiplex CCS reads with Lima (IsoSeq mode).
# Input:  CCS BAM + barcode FASTA
# Output: per-sample FL BAMs in OUT_DIR
#
# Usage:
#   bash 01_demux_lima.sh \
#     --ccs    /data/105140.ccs.bam \
#     --barcodes /data/Barcodes.fasta \
#     --out    /data/lima_out

set -euo pipefail

CCS=""
BARCODES=""
OUT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --ccs)      CCS="$2";      shift 2 ;;
        --barcodes) BARCODES="$2"; shift 2 ;;
        --out)      OUT_DIR="$2";  shift 2 ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

[[ -z "$CCS" || -z "$BARCODES" || -z "$OUT_DIR" ]] && \
    echo "Usage: $0 --ccs <ccs.bam> --barcodes <barcodes.fasta> --out <out_dir>" && exit 1

mkdir -p "${OUT_DIR}"

PREFIX="${OUT_DIR}/$(basename "${CCS%.bam}").fl"

echo "[lima] Demultiplexing ${CCS}..."
lima \
    "${CCS}" \
    "${BARCODES}" \
    "${PREFIX}.bam" \
    --isoseq \
    --peek-guess \
    --overwrite-biosample-names

echo "[lima] Done. Per-sample FL BAMs:"
ls "${OUT_DIR}"/*.fl.*.bam 2>/dev/null | grep -v "\.bam\." || echo "  (none found — check barcode FASTA names)"
