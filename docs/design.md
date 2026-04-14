# Design Notes

## Goal

`linein-passthrough` keeps motherboard line-in audible on a PipeWire desktop with low latency and stable startup behavior.

It does that by generating a static user-level PipeWire config fragment and refreshing it when the detected line-in source or output sink changes.

## How It Works

The generated config creates three loopback modules:

1. a visible virtual sink named `linein_passthrough.sink`
2. a feed loopback from the detected line-in source into that virtual sink
3. a direct loopback from the detected line-in source into the current hardware sink

The direct loopback is the actual audible passthrough path.

The virtual sink exists so KDE Plasma can expose a clean `Line-In Passthrough` output device when virtual devices are shown.

## Why The Config Is Generated

PipeWire static `libpipewire-module-loopback` configuration requires a concrete `target.object` source node.

That node name can change across:

- codec/profile changes
- docking or undocking
- kernel or ACP/UCM changes
- different desktop audio routing states

The helper keeps the final deployed config static, but regenerates it from the currently detected source and sink.

## Detection Strategy

The refresh helper looks for PipeWire `Audio/Source` nodes in this order:

1. ALSA devices that expose an available input route named `Line In`
2. source nodes whose names or descriptions explicitly contain `linein` or `line-in`
3. analog stereo ALSA source nodes that do not look like USB microphones, webcams, or headsets

That prefers a real active line-in route when PipeWire exposes one, while still avoiding most USB microphones.

For the output target, the helper uses `@DEFAULT_AUDIO_SINK@` first and falls back to a detected hardware sink if the default cannot be read or resolves to the project’s own virtual sink.

## Runtime Behavior

- `linein-passthrough enable` calls the refresh helper with `--activate`
- the helper writes `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- if the generated config changed, it restarts `pipewire.service` and `wireplumber.service`
- the login-time systemd user service reruns the helper on future logins
- the helper also sets the detected line-in source to a conservative default gain of `35%`

## Current WirePlumber Integration

The current implementation does not require a custom WirePlumber script.

The optional WirePlumber file installed by `make install-wireplumber` is only a reserved placeholder config.

## Installed Files

Core install:

- `~/.local/bin/linein-passthrough`
- `~/.local/bin/linein-passthrough-refresh`
- `~/.local/bin/linein-passthrough-uninstall`
- `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf.disabled`
- `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- `~/.config/systemd/user/linein-passthrough-refresh.service`

Optional placeholder config:

- `~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf`
