FROM balenalib/raspberry-pi-debian:latest

LABEL maintainer="Markus Brinkmann m.brinkmann@gmail.com"

RUN mkdir /build && cd /build; \
    git clone --depth 1 -b 3.1.1 https://github.com/apache/couchdb.git; \
    ls -lA;

# Add CouchDB user account to make sure the IDs are assigned consistently
RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb

RUN set -ex; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        apt-transport-https \
        ca-certificates \
        dirmngr \
        gnupg \
	libicu63 \
     ; \
    rm -rf /var/lib/apt/lists/*

VOLUME	/opt/couchdb/data

RUN	mkdir -p /opt/couchdb/data; \
	chown -R couchdb:couchdb /opt/couchdb

COPY	--chown=couchdb:couchdb ./couchdb /opt/couchdb/

USER	couchdb:couchdb

# 5984: Main CouchDB endpoint
# 4369: Erlang portmap daemon (epmd)
# 9100: CouchDB cluster communication port
EXPOSE 5984 4369 9100
CMD ["/opt/couchdb/bin/couchdb"]
