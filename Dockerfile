FROM debian:bookworm-slim

ARG PACT_VERSION=v0.18.0

RUN apt-get update && apt-get install -y \
    gcc \
    libc6-dev \
    libsqlite3-dev \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL "https://github.com/nhumrich/pact/releases/download/${PACT_VERSION}/pact-linux-x86_64" \
    -o /usr/local/bin/pact \
    && chmod +x /usr/local/bin/pact

WORKDIR /workspace

ENTRYPOINT ["pact"]
CMD ["--help"]
