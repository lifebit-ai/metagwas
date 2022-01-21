FROM python:3.9.7


RUN pip install --upgrade pip
RUN pip install pandas

RUN pip3 install scipy==1.6.1 numpy==1.19.4 pandas==1.1.4 bitarray==2.0.1

# The latest commit of mama as of today: https://github.com/JonJala/mama/commit/1686586f46c6bc860db9965c0d4fe05a42594eaf
RUN mkdir metamama && \
cd metamama && \
git init && \
git remote add origin https://github.com/JonJala/mama.git && \
git fetch origin 1686586f46c6bc860db9965c0d4fe05a42594eaf && \
git reset --hard FETCH_HEAD

USER root

RUN mkdir -p metamama/

ENV PATH=$PATH:/mama

WORKDIR metamama/

