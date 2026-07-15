FROM condaforge/miniforge3:latest

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

COPY environment.yml ./environment.yml
COPY scripts/        ./scripts/

RUN conda env create -f environment.yml && conda clean -afy

RUN conda init bash && \
    echo "conda activate preprocessing-env" >> /root/.bashrc

CMD ["bash", "-l"]
