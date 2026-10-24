# syntax=docker/dockerfile:1
# Builds the Corrosion agent image Ployz runs. Build from the repository root:
#   docker build -f ployz/Dockerfile .
FROM rust:1.89-bookworm AS build
# 16K-page arm64 kernels (Raspberry Pi 5, Asahi) need jemalloc built for 2^14-byte pages,
# or the agent aborts with "<jemalloc>: Unsupported system page size". Empty keeps jemalloc's default.
ARG JEMALLOC_SYS_WITH_LG_PAGE=
RUN apt-get update \
 && apt-get install -y --no-install-recommends clang mold \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /src
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/src/target \
    if [ -z "$JEMALLOC_SYS_WITH_LG_PAGE" ]; then unset JEMALLOC_SYS_WITH_LG_PAGE; fi \
 && cargo build --release --locked --bin corrosion \
 && objcopy --compress-debug-sections target/release/corrosion /corrosion

FROM gcr.io/distroless/cc-debian12
COPY --from=build /corrosion /usr/bin/corrosion
CMD ["corrosion", "agent"]
