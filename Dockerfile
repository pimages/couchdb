FROM balenalib/raspberry-pi-debian:latest

LABEL maintainer="Markus Brinkmann m.brinkmann@gmail.com"

# install run dependencies
RUN set -ex; \
    apt update; \
    apt install -y --no-install-recommends \
        ca-certificates \
	    libicu63 \
        libmozjs185-1.0 \
        gosu \
        tini; \
    rm -rf /var/lib/apt/lists/*; 

# Add CouchDB user account to make sure the IDs are assigned consistently
RUN groupadd -g 5984 -r couchdb && useradd -u 5984 -d /opt/couchdb -g couchdb couchdb

# Install build dependencies, build it and remove them again to keep
# image as small as possible
RUN set -ex; \
    apt update; \
    apt install -y --no-install-recommends \
        build-essential \
        git \
        erlang \
        npm \
        libicu-dev \
	    libmozjs185-dev; \
    mkdir /build && cd /build; \
    git clone --depth 1 -b 3.1.1 https://github.com/apache/couchdb.git; \
    cd couchdb && ./configure --disable-docs && make release; \
    apt purge -y \
        build-essential \
        git \
        erlang \
        npm \
        libicu-dev \
        libmozjs185-dev; \
    apt autoremove --purge -o APT::Autoremove::RecommendsImportant=0 -o APT::Autoremove::SuggestsImportant=0; \
    cp -r /build/couchdb/rel/couchdb /opt/; \
    mkdir -p /opt/couchdb/data; \
    chown -R couchdb:couchdb /opt/couchdb; \
    rm -rf /build; \
    rm -rf /root/.npm; \
    rm -rf /tmp/*; \
    rm -rf /var/lib/apt/lists/*;
    
VOLUME	/opt/couchdb/data

# Add configuration
COPY --chown=couchdb:couchdb 10-docker-default.ini /opt/couchdb/etc/default.d/
COPY --chown=couchdb:couchdb vm.args /opt/couchdb/etc/

COPY docker-entrypoint.sh /usr/local/bin
RUN ln -s usr/local/bin/docker-entrypoint.sh /docker-entrypoint.sh # backwards compat
ENTRYPOINT ["/usr/bin/tini", "--", "/docker-entrypoint.sh"]

# 5984: Main CouchDB endpoint
# 4369: Erlang portmap daemon (epmd)
# 9100: CouchDB cluster communication port
EXPOSE 5984 4369 9100
CMD ["/opt/couchdb/bin/couchdb"]
