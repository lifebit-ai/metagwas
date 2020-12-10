FROM continuumio/miniconda3@sha256:456e3196bf3ffb13fee7c9216db4b18b5e6f4d37090b31df3e0309926e98cfe2

LABEL description="Docker image containing all requirements for lifebit-ai/metagwas" \
      author="magda@lifebit.ai"

RUN apt-get update -y  \ 
    && apt-get install -y wget zip procps \
    && rm -rf /var/lib/apt/lists/*

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/metagwas/bin:$PATH

# Install METAL
RUN wget http://csg.sph.umich.edu/abecasis/Metal/download/Linux-metal.tar.gz \
    && tar -xzvf Linux-metal.tar.gz \
    && rm Linux-metal.tar.gz

ENV PATH /generic-metal:$PATH

USER root

WORKDIR /data/

CMD ["bash"]


