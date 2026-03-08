// Minimal TinyGo blink example for ESP32
package main

import (
	"machine"
	"time"
)

func main() {
	// On many ESP32 dev boards the on-board LED is on GPIO2. Adjust if needed.
	led := machine.GPIO2
	led.Configure(machine.PinConfig{Mode: machine.PinOutput})

	for {
		led.High()
		time.Sleep(500 * time.Millisecond)
		led.Low()
		time.Sleep(500 * time.Millisecond)
	}
}
