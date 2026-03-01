FROM debian:bookworm-slim
ARG TARGETPLATFORM
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY build/${TARGETPLATFORM}/corrosion /usr/local/bin/corrosion
ENTRYPOINT ["corrosion"]
