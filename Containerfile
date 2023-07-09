# -*- coding: utf-8; mode: dockerfile; -*-
FROM docker.io/library/eclipse-temurin:21
LABEL maintainer="Tom Vaughan <tvaughan@tocino.cl>"

ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

RUN apt -q update                                                               \
    && DEBIAN_FRONTEND=noninteractive                                           \
    apt-get -q -y install                                                       \
        make                                                                    \
        postgresql-client                                                       \
    && apt -q clean                                                             \
    && rm -rf /var/lib/apt/lists/*

COPY datomic-pro /opt/datomic-pro

WORKDIR /opt/datomic-pro

CMD ["make", "shell"]
