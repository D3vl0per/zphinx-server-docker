ARG ALPINE_VERSION 

FROM alpine:${ALPINE_VERSION} as zphinx-builder

ARG EQUIHASH_COMMIT \
	ZPHINX_COMMIT 

RUN apk update --no-cache \
	&& apk upgrade --no-cache \ 
	&& apk add --no-cache git \
	patch \
	libsodium \
	libsodium-dev \
	libsodium-static \
	gcc \
	g++ \
	automake \
	autoconf \
	pkgconfig \
	python3-dev \
	cmake \
	ninja \
	libc-dev \
	binutils \
	zlib-static \
	libstdc++ \
	python3-dev \
	make \
	zig 

RUN git clone https://github.com/stef/equihash.git \
        && cd equihash \
        && mkdir /usr/share/pkgconfig/ \
        && git checkout "$EQUIHASH_COMMIT" \ 
        && make PREFIX=/usr install

RUN git clone https://github.com/stef/zphinx-zerver.git \
	&& cd zphinx-zerver \
	&& git checkout "$ZPHINX_COMMIT" \
	&& git submodule update --init --recursive

RUN cd zphinx-zerver \
	&& zig build install --prefix . --release=safe

FROM alpine:${ALPINE_VERSION} as base-cert

RUN apk update --no-cache \
	&& apk add --no-cache openssl \
	&& openssl ecparam -genkey -out server.pem -name secp384r1 \
	&& openssl req -new -nodes -x509 -sha256 -key server.pem -out certs.pem -days 1 -subj '/CN=localhost'

FROM alpine:${ALPINE_VERSION} as zphinx

LABEL upstream="https://github.com/stef/zphinx-zerver" \ 
      maintainer="D3v <mark@zsibok.hu>"

ARG ZPHINX_COMMIT \
    EQUIHASH_COMMIT

LABEL zphinx-commit=$ZPHINX_COMMIT \
      equihash-commit=$EQUIHASH_COMMIT

RUN apk update --no-cache \
	&& apk upgrade --no-cache \
	&& apk add libsodium-dev --no-cache \
	&& mkdir -p /var/lib/sphinx /etc/sphinx /etc/ssl/sphinx \
		&& rm -rf /etc/apk \
		&& rm -rf /lib/apk

COPY sphinx.cfg /etc/sphinx/config
COPY --from=base-cert /server.pem /etc/ssl/sphinx/server.pem
COPY --from=base-cert /certs.pem /etc/ssl/sphinx/certs.pem

COPY --from=zphinx-builder /usr/lib/libequihash.so /usr/lib/libequihash.so
COPY --from=zphinx-builder /usr/lib/libequihash.so.0 /usr/lib/libequihash.so.0
COPY --from=zphinx-builder /usr/lib/libstdc++.so.6 /usr/lib/libstdc++.so.6
COPY --from=zphinx-builder /usr/lib/libgcc_s.so.1 /usr/lib/libgcc_s.so.1
COPY --from=zphinx-builder /zphinx-zerver/bin/oracle /usr/local/bin/oracle
COPY --from=zphinx-builder /usr/include/sodium/ /usr/include/sodium/
COPY --from=zphinx-builder /usr/include/sodium.h /usr/include/sodium.h
COPY --from=zphinx-builder /usr/lib/libpkgconf.so.* /usr/lib/
COPY --from=zphinx-builder /usr/lib/libsodium.so.* /usr/lib/

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME /var/lib/sphinx

EXPOSE 2355

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]