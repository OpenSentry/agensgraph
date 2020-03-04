FROM alpine:3.11 AS builder

RUN mkdir agens

WORKDIR agens

RUN apk add make gcc glib git musl-dev readline readline-dev bison flex perl zlib zlib-dev

RUN git clone --single-branch --branch v2.1 https://github.com/bitnine-oss/agensgraph.git .

RUN ./configure --prefix=$(pwd) || cat config.log

RUN make install
RUN echo "export PATH=/path/to/agensgraph/bin:\$PATH" >> ~/.bashrc
RUN echo "export LD_LIBRARY_PATH=/path/to/agensgraph/lib:\$LD_LIBRARY_PATH" >> ~/.bashrc

# multi stage build
FROM alpine:3.11

RUN apk add readline

COPY --from=builder /agens/bin /bin
COPY --from=builder /agens/include /include
COPY --from=builder /agens/lib /lib
COPY --from=builder /agens/share /share
COPY entrypoint.sh /entrypoint.sh

RUN addgroup agens
RUN adduser --system --disabled-password --no-create-home --ingroup agens agens

RUN mkdir -p /data
RUN chown -R agens:agens /data
RUN chmod -R 700 /data

RUN mkdir -p /logs
RUN chown -R agens:agens /logs
RUN chmod -R 700 /logs

RUN chown -R agens:agens /entrypoint.sh
RUN chmod -R 700 /entrypoint.sh

ENV AGDATA=/data \
    PATH=/bin:$PATH \
    LD_LIBRARY_PATH=/lib:$LD_LIBRARY_PATH \
    AGHOME=/

USER agens

RUN set -e
RUN initdb

RUN sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" $AGDATA/postgresql.conf
RUN echo "host	all	all	0.0.0.0/0	trust" >> $AGDATA/pg_hba.conf

EXPOSE 5432
EXPOSE 8085

ENTRYPOINT ["/entrypoint.sh"]
