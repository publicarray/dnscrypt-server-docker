## Fix Me
FROM publicarray:dnscrypt-server
LABEL maintainer="Frank Denis"
SHELL ["/bin/sh", "-x", "-c"]
ENV SERIAL 1

ENV CFLAGS=-Ofast
ENV BUILD_DEPS   curl make build-essential git libevent-dev libexpat1-dev autoconf file libssl-dev byacc
ENV RUNTIME_DEPS util-linux ldnsutils runit runit-helper jed

RUN apt-get update; apt-get -qy dist-upgrade; apt-get -qy clean && \
    apt-get install -qy --no-install-recommends $RUNTIME_DEPS && \
    rm -fr /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/* /var/log/apt/* /var/log/*.log

ENV UNBOUND_GIT_URL https://github.com/jedisct1/unbound.git
ENV UNBOUND_GIT_REVISION 5d6bdf5a1c343205bba70999418de8335dc3b4f6

WORKDIR /tmp

RUN apt-get update; apt-get install -qy --no-install-recommends $BUILD_DEPS && \
    git clone --depth=1000 "$UNBOUND_GIT_URL" && \
    cd unbound && \
    git checkout "$UNBOUND_GIT_REVISION" && \
    groupadd _unbound && \
    useradd -g _unbound -s /etc -d /dev/null _unbound && \
    ./configure --prefix=/opt/unbound --with-pthreads \
    --with-username=_unbound --with-libevent --enable-event-api && \
    make -j"$(getconf _NPROCESSORS_ONLN)" install && \
    mv /opt/unbound/etc/unbound/unbound.conf /opt/unbound/etc/unbound/unbound.conf.example && \
    apt-get -qy purge $BUILD_DEPS && apt-get -qy autoremove && \
    rm -fr /opt/unbound/share/man && \
    rm -fr /tmp/* /var/tmp/* /var/cache/apt/* /var/lib/apt/lists/* /var/log/apt/* /var/log/*.log

RUN mkdir -p \
    /etc/service/unbound \
    /etc/service/watchdog

COPY encrypted-dns.toml.in /opt/encrypted-dns/etc/

COPY unbound.sh /etc/service/unbound/run
COPY unbound-check.sh /etc/service/unbound/check

COPY encrypted-dns.sh /etc/service/encrypted-dns/run

COPY watchdog.sh /etc/service/watchdog/run

VOLUME ["/opt/encrypted-dns/etc/keys"]

EXPOSE 443/udp 443/tcp 9100/tcp

CMD ["/entrypoint.sh", "start"]

ENTRYPOINT ["/entrypoint.sh"]
