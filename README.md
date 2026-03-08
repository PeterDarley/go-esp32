# go-esp32 (devcontainer stub)

This repository has been converted to a Go devcontainer scaffold.

What this repo contains now:
- a minimal Go devcontainer: [.devcontainer/devcontainer.json](.devcontainer/devcontainer.json)
- a simple Dockerfile for the container: [.devcontainer/Dockerfile](.devcontainer/Dockerfile)
- an empty Go module: [go.mod](go.mod)
- ESP32 helper scripts retained: `attach-esp32.ps1`, `check-esp32.sh`, `flash.sh`

 The previous embedded example project has been removed from active development
 and its key manifest files replaced with placeholders. The ESP32 helper scripts
 listed above were intentionally kept to support device workflows.
 
 If you want, I can fully archive or delete the original sources next.

Blink example (TinyGo)

To build and flash the minimal blink example (requires TinyGo):

```
make build        # builds build/firmware.bin using TinyGo
make flash PORT=/dev/ttyUSB0
```

You can build inside the devcontainer (recommended) — the container image includes TinyGo and `esptool`.

