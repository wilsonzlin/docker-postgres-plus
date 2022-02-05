FROM ubuntu:20.04

RUN apt -yqq update && apt -yqq install cmake gcc libssl-dev make sudo zlib1g-dev

WORKDIR /tmp
ADD pg.tar.gz .
RUN mv -v postgresql-* pg
WORKDIR /tmp/pg
RUN ./configure --prefix /usr --with-openssl --without-readline
RUN make -j $NPROC world
RUN make install-world
RUN rm -rf /tmp/pg

WORKDIR /tmp
ADD rum.tar.gz .
RUN mv -v rum-* rum
WORKDIR /tmp/rum
RUN make -j $NPROC USE_PGXS=1
RUN make install USE_PGXS=1
RUN rm -rf /tmp/rum

WORKDIR /tmp
ADD ts.tar.gz .
RUN mv -v timescaledb-* ts
WORKDIR /tmp/ts
RUN ./bootstrap -DREGRESS_CHECKS=OFF
WORKDIR /tmp/ts/build
RUN make -j $NPROC
RUN make install
RUN rm -rf /tmp/ts

ADD postgresql-init.conf /postgresql-init.conf
ADD postgresql.conf /postgresql.conf
RUN useradd --system --user-group --shell /sbin/nologin postgres
RUN mkdir /pgdata && chown postgres:postgres /pgdata
RUN mkdir /pgsock && chown postgres:postgres /pgsock

CMD sudo -u postgres initdb --pgdata=/pgdata --username=postgres && \
  cp /postgresql-init.conf /pgdata/postgresql.conf && \
  echo "local all postgres trust" > /pgdata/pg_hba.conf && \
  sudo -u postgres pg_ctl -D /pgdata --log=/pgdata/server.log --wait start && \
  psql --no-readline --host /pgsock --user postgres --db postgres --command "CREATE USER "\""$POSTGRES_USER"\"" WITH SUPERUSER ENCRYPTED PASSWORD '$POSTGRES_PASSWORD'" && \
  psql --no-readline --host /pgsock --user postgres --db postgres --command "CREATE DATABASE "\""$POSTGRES_DB"\"" WITH OWNER = "\""$POSTGRES_USER"\""" && \
  cp /postgresql.conf /pgdata/postgresql.conf && \
  echo "host $POSTGRES_DB $POSTGRES_USER 0.0.0.0/0 scram-sha-256" > /pgdata/pg_hba.conf && \
  sudo -u postgres pg_ctl -D /pgdata --log=/pgdata/server.log --wait restart && \
  tail -fn +1 /pgdata/server.log
