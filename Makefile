BOARD ?= esp32-mini32
PORT ?= /dev/ttyUSB0
BINARY = build/firmware.bin

.PHONY: all build flash clean
all: build

build:
	@mkdir -p build
	@echo "Building for $(BOARD)..."
	@tinygo build -o $(BINARY) -target=$(BOARD) .

flash:
	@if [ ! -f $(BINARY) ]; then \
		echo "Firmware not built; run 'make build' first."; exit 1; \
	fi
	@echo "Flashing to $(PORT)..."
	@esptool --chip esp32 --port $(PORT) write-flash -z 0x1000 $(BINARY)

clean:
	@rm -rf build
