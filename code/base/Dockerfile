FROM ubuntu:24.04 AS openssl_builder

RUN apt update && \
    apt install -y make gcc wget gnupg perl && \
    apt clean

WORKDIR /root

RUN wget https://github.com/openssl/openssl/releases/download/openssl-3.5.0/openssl-3.5.0.tar.gz && \
    wget https://github.com/openssl/openssl/releases/download/openssl-3.5.0/openssl-3.5.0.tar.gz.asc

RUN gpg --keyserver keyserver.ubuntu.com --recv-keys 216094DFD0CB81EF

RUN gpg --verify openssl-3.5.0.tar.gz.asc openssl-3.5.0.tar.gz

RUN tar zxf openssl-3.5.0.tar.gz && \
    cd openssl-3.5.0 && \
    ./Configure --prefix=/opt '-Wl,-rpath,$(LIBRPATH)' && \
    make && \
    make install

ENV PATH="/opt/bin:${PATH}"
