BOARD ?= esp32-mini32
PORT  ?= /dev/ttyUSB0

# TinyGo blink firmware (bare-metal, no WiFi)
BINARY = build/firmware.bin

# Arduino board FQBN for esp32-mini32
# Using the Espressif Arduino ESP32 core (3.x series)
ARDUINO_FQBN  ?= esp32:esp32:esp32
ARDUINO_SPEED ?= 115200
SOFTAP_DIR     = softap

.PHONY: all build flash flash-softap monitor clean

all: build

# ── TinyGo blink ──────────────────────────────────────────────────────────
build:
	@mkdir -p build
	@echo "Building TinyGo firmware for $(BOARD)..."
	@tinygo build -o $(BINARY) -target=$(BOARD) .

flash:
	@if [ ! -f $(BINARY) ]; then \
		echo "Firmware not built; run 'make build' first."; exit 1; \
	fi
	@echo "Flashing TinyGo firmware to $(PORT)..."
	@esptool --chip esp32 --port $(PORT) write-flash -z 0x1000 $(BINARY)

# ── Arduino SoftAP + HTTP server ──────────────────────────────────────────
# Requires arduino-cli with the esp32:esp32 core installed.
# First-time setup (done automatically in devcontainer, or run manually):
#   arduino-cli core update-index \
#       --additional-urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
#   arduino-cli core install esp32:esp32 \
#       --additional-urls https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
flash-softap:
	@echo "Compiling & flashing SoftAP sketch to $(PORT) (FQBN: $(ARDUINO_FQBN))..."
	@arduino-cli compile \
		--fqbn "$(ARDUINO_FQBN)" \
		--build-property "build.extra_flags=-DARDUINO_RUNNING_CORE=1" \
		"$(SOFTAP_DIR)"
	@arduino-cli upload \
		--fqbn "$(ARDUINO_FQBN)" \
		--port "$(PORT)" \
		"$(SOFTAP_DIR)"
	@echo "Done. Join WiFi 'peter_bot' and open http://192.168.71.1/"

# ── Serial monitor ────────────────────────────────────────────────────────
monitor:
	@echo "Opening serial monitor on $(PORT) at $(ARDUINO_SPEED) baud  (exit: Ctrl-A Ctrl-X)"
	@picocom --baud $(ARDUINO_SPEED) --flow n --databits 8 --parity n "$(PORT)" \
		|| arduino-cli monitor --port "$(PORT)" --config "baudrate=$(ARDUINO_SPEED)"

# ── Clean ─────────────────────────────────────────────────────────────────
clean:
	@rm -rf build
