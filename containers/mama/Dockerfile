FROM python:3.9.7


RUN pip install --upgrade pip
RUN pip install pandas

RUN pip3 install scipy==1.6.1 numpy==1.19.4 pandas==1.1.4 bitarray==2.0.1

RUN git clone https://github.com/JonJala/mama.git

USER root

RUN mkdir -p metamama/

ENV PATH=$PATH:/mama

WORKDIR metamama/

