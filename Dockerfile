FROM ghcr.io/rust-cross/rust-musl-cross:x86_64-musl AS builder

ARG TARGET=x86_64-unknown-linux-musl

WORKDIR /source

RUN set -xe \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    git=1:2.34.1-1ubuntu1.17 \
    cmake=3.22.1-1ubuntu1.22.04.2 \
    perl=5.34.0-3ubuntu1.8 \
    pkg-config=0.29.2-1ubuntu3 \
    libclang-dev=1:14.0-55~exp2 \
    && rustup target add ${TARGET} \
    && rm -rf /var/lib/apt/lists/*

RUN set -xe \
    && git clone https://github.com/redlib-org/redlib . \
    && git checkout a4d36e954cf1bd64f209cd8868c5a29edc81b374 \
    && RUSTFLAGS='-C target-feature=+crt-static' cargo build --release --target ${TARGET} \
    && mkdir /app \
    && mv target/${TARGET}/release/redlib /app/redlib \
    && chmod +x /app/redlib

FROM ubuntu:noble AS final

LABEL org.opencontainers.image.authors="Maja Bojarska <majabojarska98@gmail.com>"

RUN set -xe \
    && apt-get update \
    # Common
    && apt-get install -y --no-install-recommends \
    wget=1.21.4-1ubuntu4.5 \
    # Cleanup
    && apt-get autoremove -y --purge \
    && apt-get -q clean -y && rm -rf /var/lib/apt/lists/* && rm -f /var/cache/apt/*.bin

COPY --from=builder /app/redlib /usr/bin/redlib

# Default user in Ubuntu Noble.
USER 1000

HEALTHCHECK --interval=1m --timeout=3s CMD ["wget", "--spider", "-q", "http://localhost:8080/settings"]

EXPOSE 8080
VOLUME [ "/config" ]
ENTRYPOINT ["redlib"]
