# linein-passthrough

Persistent, low-latency line-in passthrough for PipeWire desktops.

`linein-passthrough` creates a persistent `libpipewire-module-loopback` between your motherboard line-in jack and your current default speakers/headphones while leaving your USB microphone alone as the default recording device.

It is built for KDE on Bazzite, but the approach is generic and works on any modern PipeWire + WirePlumber desktop.

## What it does

- Uses a static `pipewire.conf.d` loopback module for persistence.
- Auto-detects a likely analog line-in source.
- Targets your current default audio sink for playback.
- Exposes a small CLI with `enable`, `disable`, `toggle`, `status`, and `refresh`.
- Uses `notify-send` when available.
- Optionally installs a WirePlumber Lua helper so the loopback node shows as `Line-In Passthrough` in KDE's volume applet.
- Avoids changing the default source, so your USB mic can remain your default recording device.

## Why the project generates the config

PipeWire's static `libpipewire-module-loopback` configuration needs a concrete `target.object` source node name.
Those names vary across hardware and can change after profile changes, kernel updates, or different ACP/UCM behavior.

This project keeps the actual loopback persistent in `pipewire.conf.d`, but generates that static file from the currently detected Line-In node. The generated file remains a normal static PipeWire config; the helper just refreshes it when the real node name changes.

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
    scripts/90-linein-passthrough.lua
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
- installs and enables a user systemd refresh service
- optionally installs the WirePlumber Lua helper for a cleaner KDE-visible name
- enables the passthrough immediately

## Manual install

If you prefer to copy files yourself:

```bash
install -Dm0755 bin/linein-passthrough ~/.local/bin/linein-passthrough
install -Dm0755 libexec/linein-passthrough-refresh ~/.local/bin/linein-passthrough-refresh
install -Dm0644 systemd/linein-passthrough-refresh.service ~/.config/systemd/user/linein-passthrough-refresh.service
systemctl --user daemon-reload
systemctl --user enable --now linein-passthrough-refresh.service
~/.local/bin/linein-passthrough enable
```

Optional WirePlumber helper:

```bash
install -Dm0644 config/wireplumber/90-linein-passthrough.conf ~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf
install -Dm0644 config/wireplumber/scripts/90-linein-passthrough.lua ~/.local/share/wireplumber/scripts/90-linein-passthrough.lua
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
- restarts `pipewire.service` and `wireplumber.service` if the config changed

### `disable`

- removes the generated loopback config
- restarts user audio services

### `refresh`

- re-detects the source and sink
- rewrites the config only if the generated content changed
- useful after changing audio profiles or docking hardware

## How detection works

The refresh helper looks for PipeWire `Audio/Source` nodes in this order:

1. names or descriptions that explicitly contain `linein` or `line-in`
2. analog stereo ALSA source nodes that do not look like USB microphones, webcams, or headsets

That keeps the onboard blue jack preferred while avoiding most USB mics.

Playback always targets the current default sink reported by PipeWire.

## Files installed on your system

- `~/.local/bin/linein-passthrough`
- `~/.local/bin/linein-passthrough-refresh`
- `~/.local/bin/linein-passthrough-uninstall`
- `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- `~/.config/systemd/user/linein-passthrough-refresh.service`

Optional:

- `~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf`
- `~/.local/share/wireplumber/scripts/90-linein-passthrough.lua`

## KDE system tray appearance

With the optional WirePlumber helper, KDE's volume applet should show the playback-side node with a friendly label:

`Line-In Passthrough`

Without the helper, the node still works, but the visible name may be less polished depending on how your desktop surfaces PipeWire stream metadata.

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

### USB microphone became the default source

This project does not explicitly set the default source. If your default source changes, that is a desktop or WirePlumber policy issue outside the loopback module itself.

Check your current defaults:

```bash
wpctl status
wpctl inspect @DEFAULT_AUDIO_SOURCE@
```

Then re-select your USB microphone as the default recording device in KDE or with `wpctl set-default`.

### The KDE applet does not show `Line-In Passthrough`

Install the optional WirePlumber helper and restart WirePlumber:

```bash
./bin/linein-passthrough-install --with-wireplumber-lua
```

If your distribution uses a WirePlumber setup that disables custom Lua scripts, the loopback still works, but the polished visible name may not be applied.

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

This rewrites the loopback target to the current default sink.

## Notes for advanced users

- The generated PipeWire fragment intentionally uses `libpipewire-module-loopback` directly in `pipewire.conf.d` for persistence.
- The helper marks both loopback ends as passive and disables reconnect attempts so WirePlumber can manage graph policy cleanly.
- The refresh service is user-scoped, runs at login, and avoids touching system-wide PipeWire files.
- If you want an even lower or different latency target, edit the generated properties in `libexec/linein-passthrough-refresh`.

## License

MIT
