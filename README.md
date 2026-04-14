# linein-passthrough

Persistent, low-latency line-in passthrough for PipeWire desktops.

`linein-passthrough` creates a persistent PipeWire virtual sink named `Line-In Passthrough` for KDE visibility and also maintains a direct low-latency loopback from your motherboard line-in jack to your current hardware output while leaving your USB microphone alone as the default recording device.

It is built for KDE on Bazzite, but the approach is generic and works on any modern PipeWire + WirePlumber desktop.

## What it does

- Uses static `pipewire.conf.d` loopback modules for persistence.
- Auto-detects a likely analog line-in source.
- Creates a user-visible virtual sink named `Line-In Passthrough`.
- Keeps an always-on direct loopback to the current hardware output for actual passthrough audio.
- Keeps the virtual sink separate from the direct audio path so the passthrough remains audible.
- Exposes a small CLI with `enable`, `disable`, `toggle`, `status`, and `refresh`.
- Uses `notify-send` when available.
- Optionally installs a reserved WirePlumber config placeholder.
- Avoids changing the default source, so your USB mic can remain your default recording device.
- Applies a conservative Line-In source gain on enable to reduce clipping on hot analog inputs.

## Why the project generates the config

PipeWire's static `libpipewire-module-loopback` configuration still needs a concrete source node name for the real motherboard Line-In path.
Those names vary across hardware and can change after profile changes, kernel updates, or different ACP/UCM behavior.

This project keeps the actual loopbacks persistent in `pipewire.conf.d`, but generates that static file from the currently detected Line-In node. The generated file remains a normal static PipeWire config; the helper just refreshes it when the real node name changes.

## Repository layout

```text
bin/
  linein-passthrough
  linein-passthrough-install
  linein-passthrough-uninstall
config/
  pipewire/
    90-linein-passthrough.conf.disabled
  wireplumber/
    90-linein-passthrough.conf
libexec/
  linein-passthrough-refresh
systemd/
  linein-passthrough-refresh.service
```

## Requirements

- PipeWire
- WirePlumber
- `wpctl`
- `pw-dump`
- `jq`
- `systemctl --user`
- `pactl`
- `notify-send` optional

On Bazzite and most KDE PipeWire desktops, these are already present. If `jq` is missing, install it first.

## Bazzite and KDE install

From the project directory:

```bash
chmod +x bin/linein-passthrough-install bin/linein-passthrough libexec/linein-passthrough-refresh
./bin/linein-passthrough-install --with-wireplumber-lua
```

Or with `make`:

```bash
make install-wireplumber
```

That command:

- installs the CLI into `~/.local/bin`
- installs a generated PipeWire config target in `~/.config/pipewire/pipewire.conf.d`
- installs and enables a user systemd refresh service for future logins
- optionally installs a reserved WirePlumber config placeholder
- enables the passthrough immediately

## Manual install

If you prefer to copy files yourself:

```bash
install -Dm0755 bin/linein-passthrough ~/.local/bin/linein-passthrough
install -Dm0755 libexec/linein-passthrough-refresh ~/.local/bin/linein-passthrough-refresh
install -Dm0644 systemd/linein-passthrough-refresh.service ~/.config/systemd/user/linein-passthrough-refresh.service
systemctl --user daemon-reload
systemctl --user enable linein-passthrough-refresh.service
~/.local/bin/linein-passthrough enable
```

Optional WirePlumber placeholder config:

```bash
install -Dm0644 config/wireplumber/90-linein-passthrough.conf ~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf
systemctl --user restart wireplumber.service
```

## Uninstall

```bash
~/.local/bin/linein-passthrough-uninstall
```

Or with `make`:

```bash
make uninstall
```

To keep the optional WirePlumber Lua helper installed:

```bash
~/.local/bin/linein-passthrough-uninstall --keep-wireplumber-lua
```

## CLI usage

```bash
linein-passthrough enable
linein-passthrough disable
linein-passthrough toggle
linein-passthrough status
linein-passthrough refresh
```

### `enable`

- detects a likely Line-In source node
- writes `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- creates a virtual sink called `Line-In Passthrough`
- non-blocking restarts `pipewire.service` and `wireplumber.service` if the config changed

### `disable`

- removes the generated loopback config
- restarts user audio services

### `refresh`

- re-detects the Line-In source
- rewrites the config only if the generated content changed
- useful after changing audio profiles or codec routes

## How detection works

The refresh helper looks for PipeWire `Audio/Source` nodes in this order:

1. ALSA devices that expose an available input route named `Line In`
2. source nodes whose names or descriptions explicitly contain `linein` or `line-in`
3. analog stereo ALSA source nodes that do not look like USB microphones, webcams, or headsets

That prefers a real active Line-In route when PipeWire exposes one, while still avoiding most USB mics.

The generated config creates:

1. a virtual sink main node named `linein_passthrough.sink`
2. a second loopback that captures the real Line-In source and plays it into that virtual sink
3. a third loopback that captures the real Line-In source and plays it directly into the current hardware sink

The direct loopback is what carries the audible passthrough. The virtual sink exists so Plasma can expose a clean `Line-In Passthrough` output device when virtual devices are shown.

## Files installed on your system

- `~/.local/bin/linein-passthrough`
- `~/.local/bin/linein-passthrough-refresh`
- `~/.local/bin/linein-passthrough-uninstall`
- `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- `~/.config/systemd/user/linein-passthrough-refresh.service`

Optional:

- `~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf`

## KDE system tray appearance

The intended visible playback object is a virtual sink named:

`Line-In Passthrough`

This is now implemented as an `Audio/Sink`, not only as an internal loopback stream.

## Troubleshooting

### No sound from line-in

Run:

```bash
linein-passthrough status
linein-passthrough refresh
wpctl status
```

Check that:

- your motherboard input is actually exposed as a source node
- the correct port/profile is selected for the audio card
- the line-in jack is not muted in ALSA/firmware
- the Line-In source volume is not set too hot for your external device

### The wrong source was chosen

Inspect available source nodes:

```bash
pw-dump | jq -r '.[]
  | select(.type == "PipeWire:Interface:Node")
  | select(.info.props["media.class"] == "Audio/Source")
  | [.id, .info.props["node.name"], .info.props["node.nick"], .info.props["node.description"]]
  | @tsv'
```

If your device does not match the default heuristics, edit `libexec/linein-passthrough-refresh` and adjust the source matching logic for your hardware.

### Audio is clipping or distorted

The helper sets the detected Line-In source to a conservative default gain on enable, but some external devices still output a much hotter signal than a motherboard Line-In expects.

Lower the capture gain further if needed:

```bash
wpctl status
wpctl set-volume <line-in-node-id> 0.20
```

The `linein-passthrough status` command prints the detected Line-In node id for convenience.

### USB microphone became the default source

This project does not explicitly set the default source. If your default source changes, that is a desktop or WirePlumber policy issue outside the loopback module itself.

Check your current defaults:

```bash
wpctl status
wpctl inspect @DEFAULT_AUDIO_SOURCE@
```

Then re-select your USB microphone as the default recording device in KDE or with `wpctl set-default`.

### The KDE applet does not show `Line-In Passthrough`

Restart PipeWire and WirePlumber, then refresh the config:

```bash
./bin/linein-passthrough-install --with-wireplumber-lua
```

Also check whether Plasma is hiding virtual devices in the volume panel. The PipeWire side now exposes a virtual sink, but Plasma may still apply its own visibility rules.

### Audio services fail to restart

Inspect user service logs:

```bash
systemctl --user status pipewire.service wireplumber.service linein-passthrough-refresh.service
journalctl --user -u pipewire.service -u wireplumber.service -u linein-passthrough-refresh.service --no-pager -n 200
```

### I changed speakers or docked/undocked

Run:

```bash
linein-passthrough refresh
```

This rewrites the config if the detected Line-In source or the current hardware sink changed.

## Notes for advanced users

- The generated PipeWire fragment intentionally uses `libpipewire-module-loopback` directly in `pipewire.conf.d` for persistence.
- The first loopback creates a virtual sink using `media.class = Audio/Sink`.
- The second loopback feeds the detected Line-In source into that virtual sink for KDE-visible device presentation.
- The third loopback feeds the detected Line-In source directly into the current hardware sink for actual always-on passthrough audio.
- The refresh service is user-scoped, runs at login, and avoids touching system-wide PipeWire files.
- If you want an even lower or different latency target, edit the generated properties in `libexec/linein-passthrough-refresh`.

## License

MIT
