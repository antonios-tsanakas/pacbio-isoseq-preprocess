# Pacbio-Isoseq-Preprocess

A minimal, reproducible pipeline for preprocessing PacBio IsoSeq data into coordinate-sorted BAM files ready for downstream RNA-seq analysis.

---

## What this does

```
CCS BAM (raw PacBio output)
    │
    ▼  lima --isoseq           [Step 1: demultiplex]
FL BAMs (one per barcode)
    │
    ▼  isoseq3 refine          [Step 2: FLNC extraction + poly-A filter]
FLNC BAMs
    │
    ▼  minimap2 splice:hq      [Step 3: splice-aware alignment]
    │  samtools sort (coord)
    ▼
Coord-sorted BAM + .bai        [ready for downstream tools]
```

The output is a standard coordinate-sorted BAM per sample. This is the required input for:
- **Gene fusion detection**: OmniFuse, JAFFA, FusionCatcher
- **Isoform quantification**: FLAMES, SQANTI3
- **Alternative splicing**: rMATS-long, SUPPA2

---

## Quick start

### With Docker (recommended)

```bash
# Build the image (once)
docker build -t pacbio-isoseq-preprocess .

# Run the full pipeline
docker run --rm \
  -v /path/to/data:/data \
  pacbio-isoseq-preprocess \
  conda run -n preprocessing-env bash /workspace/scripts/run_all.sh \
    --ccs      /data/project.ccs.bam \
    --barcodes /data/Barcodes.fasta \
    --genome   /data/refs/genome.fa \
    --out      /data/output \
    --threads  8
```

### With conda (no Docker)

```bash
conda env create -f environment.yml
conda activate preprocessing-env

bash scripts/run_all.sh \
    --ccs      /data/project.ccs.bam \
    --barcodes /data/Barcodes.fasta \
    --genome   /data/refs/genome.fa \
    --out      /data/output \
    --threads  8
```

---

## Running steps individually

```bash
# Step 1 — demultiplex
bash scripts/01_demux_lima.sh \
    --ccs      project.ccs.bam \
    --barcodes Barcodes.fasta \
    --out      output/lima

# Step 2 — FLNC extraction
bash scripts/02_isoseq3_refine.sh \
    --fl-dir   output/lima \
    --barcodes Barcodes.fasta \
    --out      output/isoseq_refine

# Step 3 — alignment
bash scripts/03_align_minimap2.sh \
    --flnc-dir output/isoseq_refine \
    --genome   refs/genome.fa \
    --out      output/aligned \
    --threads  8
```

---

## Output structure

```
output/
  lima/
    project.fl.bc1001_5p--bc1001_3p.bam   per-sample FL BAMs
    project.fl.bc1002_5p--bc1002_3p.bam
    ...
  isoseq_refine/
    bc1001.flnc.bam                        FLNC reads (chimera-free, poly-A)
    bc1002.flnc.bam
    ...
  aligned/
    bc1001.flnc.minimap2.bam               coord-sorted, indexed — downstream input
    bc1001.flnc.minimap2.bam.bai
    bc1002.flnc.minimap2.bam
    bc1002.flnc.minimap2.bam.bai
    ...
```

---

## Key parameters

| Step | Parameter | Default | Notes |
|---|---|---|---|
| `run_all.sh` | `--threads` | `8` | Used for minimap2 and samtools. Reduce if RAM < 16 GB (minimap2 needs ~2 GB per thread + 8 GB for the genome index). |
| `01_demux_lima.sh` | `--barcodes` | — | Must match the primers used in the sequencing run |
| `02_isoseq3_refine.sh` | `--require-polya` | always on | Removes reads without a poly-A tail (IsoSeq standard) |
| `03_align_minimap2.sh` | `-ax splice:hq` | always on | Splice-aware preset for high-quality long reads |

**RAM note:** minimap2 with a mammalian genome (human GRCh38 / mouse GRCm39) requires ~8 GB for the index plus ~2 GB per thread. With `--threads 8` you need ~24 GB. Reduce to `--threads 4` for machines with 16 GB RAM.

---

## Reference genomes

| Organism | Genome | GENCODE annotation |
|---|---|---|
| Human | GRCh38 / hg38 | gencode.v47.annotation.gtf.gz |
| Mouse | GRCm39 / mm39 | gencode.vM38.annotation.gtf.gz |

The alignment step only requires the genome FASTA. Gene annotation (GTF) is used by downstream tools, not here.

---

## Requirements

- conda or Docker
- Tools installed by `environment.yml`: lima, isoseq3, minimap2, samtools
  

## Why Use This Pipeline? 

* **No SMRTPipe/XML Clutter:** Older workflows require raw subreads and SMRT Link XML dataset wrappers. This pipeline works directly on modern, standard CCS BAM formats which most sequencing cores deliver by default.
* **Fast-Track to Downstream Tools:** Instead of forcing you into a specific annotation or collapsing tool, this pipeline does one thing perfectly: it stops at indexed, coordinate-sorted BAM files. This is the precise entry format required for standard downstream packages like SQANTI3, FLAMES, rMATS-long, and SUPPA2.
* **Lightweight & Containerized:** Skip the Nextflow engine tax. If you have Docker or Conda, you can run the entire multi-sample preprocessing workflow with a single copy-paste command.
* **Resource-Aware:** Pre-configured with safety warnings and explicit memory guards for `minimap2` alignment, protecting local workstations and shared servers from out-of-memory (OOM) crashes on mammalian genomes.
