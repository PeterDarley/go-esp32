FROM mcr.microsoft.com/devcontainers/go:1

# Minimal additions for the devcontainer environment
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && usermod -aG dialout vscode

WORKDIR /workspaces

# ── arduino-cli ───────────────────────────────────────────────────────────
# Used to build and flash the SoftAP sketch (softap/softap.ino).
# The ESP32 Arduino core (~350 MB) is installed here so the image is
# self-contained; it is cached in a Docker layer.
ARG ARDUINO_CLI_VERSION=1.1.1
RUN set -eux; \
    curl -fsSL "https://downloads.arduino.cc/arduino-cli/arduino-cli_${ARDUINO_CLI_VERSION}_Linux_64bit.tar.gz" \
        -o /tmp/arduino-cli.tar.gz; \
    tar -C /usr/local/bin -xzf /tmp/arduino-cli.tar.gz arduino-cli; \
    rm /tmp/arduino-cli.tar.gz; \
    arduino-cli version

# Install the Espressif ESP32 Arduino board package (3.x series uses arduino-esp32)
RUN arduino-cli core update-index \
        --additional-urls "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json" \
    && arduino-cli core install esp32:esp32 \
        --additional-urls "https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json"
# ─────────────────────────────────────────────────────────────────────────

# Install TinyGo, esptool, Rust toolchain, and espflash for building/flashing firmware
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl tar ca-certificates python3 python3-pip build-essential gnupg2 \
    && python3 -m pip install --no-cache-dir --break-system-packages esptool \
    && rm -rf /var/lib/apt/lists/*

# Download TinyGo (explicit version to keep builds stable). Adjust version as needed.
ARG TINYGO_VERSION=0.40.1
ENV TINYGO_URL="https://github.com/tinygo-org/tinygo/releases/download/v${TINYGO_VERSION}/tinygo${TINYGO_VERSION}.linux-amd64.tar.gz"
ENV PATH="/usr/local/tinygo/bin:${PATH}"
RUN set -eux; \
        echo "Downloading TinyGo from ${TINYGO_URL}"; \
        curl -fSL -o /tmp/tinygo.tar.gz "${TINYGO_URL}"; \
        tar -C /usr/local -xzf /tmp/tinygo.tar.gz; \
        rm -f /tmp/tinygo.tar.gz; \
        ln -s /usr/local/tinygo/bin/tinygo /usr/local/bin/tinygo || true; \
        /usr/local/tinygo/bin/tinygo version

# Install Rust (non-interactive) and espflash
ENV PATH="/root/.cargo/bin:/usr/local/tinygo/bin:${PATH}"
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
    && . $HOME/.cargo/env \
    && cargo install espflash --locked || (echo "cargo install espflash failed"; exit 1)
