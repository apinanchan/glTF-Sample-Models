FROM ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    gcc \
    g++ \
    libmariadb-dev \
    libmariadb-dev-compat \
    zlib1g-dev \
    libpcre3-dev \
    make \
    wget \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build

# Clone rAthena (latest, supports Episode 21 + 4th jobs + level 275)
RUN git clone --depth 1 https://github.com/rathena/rathena.git .

# Patch MAX_LEVEL to support base level 275
RUN sed -i 's/#define MAX_LEVEL.*/#define MAX_LEVEL 300/' src/config/core.hpp || true

# Build renewal server with 4th job support
RUN ./configure --enable-renewal && make server -j$(nproc)

# ─── Runtime Stage ────────────────────────────────────────────────────────────
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    libmariadb3 \
    zlib1g \
    libpcre3 \
    mysql-client \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rathena

# Copy compiled server and all required files
COPY --from=builder /build /rathena/

# Override with our custom configuration
COPY conf/ conf/

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 6900 6121 5121

ENTRYPOINT ["/entrypoint.sh"]
