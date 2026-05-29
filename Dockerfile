# =========================
# Build Stage
# =========================
FROM rust:1.96-slim AS builder

WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# -------------------------
# Cache dependencies
# -------------------------
COPY Cargo.toml Cargo.lock ./

RUN mkdir -p src \
    && echo 'fn main() {}' > src/main.rs \
    && cargo build --release \
    && rm -rf src

# -------------------------
# Copy real source
# -------------------------
COPY src ./src

# Rebuild actual application
RUN touch src/main.rs \
    && cargo build --release

# =========================
# Runtime Stage
# =========================
FROM debian:trixie-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy CA certificates (important for HTTPS requests)
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

# Copy compiled binary
COPY --from=builder /app/target/release/kaobot /kaobot

# Environment variables
ENV RUST_LOG="kaobot=info,teloxide=warn"

# Run application
CMD ["/kaobot"]
