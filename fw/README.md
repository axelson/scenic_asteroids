# Asteroids Nerves Application

To run the Nerves app:
  * `export MIX_TARGET=my_target` or prefix every command with
    `MIX_TARGET=my_target`. For example, `MIX_TARGET=rpi3`
  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

To update an already running project

Note: if scenic doesn't launch then you may be affected by the bug https://github.com/boydm/scenic_new/issues/36 to fix it run the following:
```
rm -rf _build
mix firmware
mix firmware.burn
```
