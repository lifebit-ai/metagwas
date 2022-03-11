FROM continuumio/miniconda3:latest

LABEL description="Docker image containing all requirements for lifebit-ai/metagwas" \
      author="magda@lifebit.ai"

RUN apt-get update -y  \ 
    && apt-get install -y wget zip procps cmake g++ zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# Install METAL
RUN wget https://github.com/statgen/METAL/archive/refs/tags/2020-05-05.tar.gz \
    && tar -xzf 2020-05-05.tar.gz \
    && cd METAL-2020-05-05 \
    && cmake -DCMAKE_BUILD_TYPE=Release . \
    && make \
    && make test \
    && make install \
    && cd / \
    && cp METAL-2020-05-05/bin/metal /bin/ \
    && rm -rf 2020-05-05.tar.gz METAL-2020-05-05

COPY environment.yml /
RUN conda env create -f /environment.yml && conda clean -a
ENV PATH /opt/conda/envs/metagwas/bin:$PATH

USER root

WORKDIR /data/

CMD ["bash"]


