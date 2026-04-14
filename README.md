# linein-passthrough

Persistent, low-latency line-in passthrough for PipeWire desktops.

`linein-passthrough` creates a persistent PipeWire virtual sink named `Line-In Passthrough` for KDE visibility and maintains a direct low-latency loopback from your motherboard line-in jack to your current hardware output without changing your default recording source.

It is built for KDE on Bazzite, but the approach is generic and works on modern PipeWire + WirePlumber desktops.

## What It Is

- Persistent line-in passthrough using static `pipewire.conf.d` loopbacks.
- A small CLI for enable, disable, toggle, status, and refresh.
- A login-time user service that refreshes the generated config when your audio topology changes.
- A visible virtual sink named `Line-In Passthrough` so Plasma can expose it cleanly.

## Requirements

- PipeWire
- WirePlumber
- `wpctl`
- `pw-dump`
- `pw-cli`
- `jq`
- `pactl`
- `systemctl --user`

`notify-send` is optional.

## Quick Start

From the project directory:

```bash
make install
```

Then verify it is active:

```bash
linein-passthrough status
```

If you want the optional reserved WirePlumber placeholder config installed too:

```bash
make install-wireplumber
```

Or directly:

```bash
./bin/linein-passthrough-install --with-wireplumber-config
```

## Manual Install

```bash
install -Dm0755 bin/linein-passthrough ~/.local/bin/linein-passthrough
install -Dm0755 libexec/linein-passthrough-refresh ~/.local/bin/linein-passthrough-refresh
install -Dm0755 bin/linein-passthrough-uninstall ~/.local/bin/linein-passthrough-uninstall
install -Dm0644 systemd/linein-passthrough-refresh.service ~/.config/systemd/user/linein-passthrough-refresh.service
systemctl --user daemon-reload
systemctl --user enable linein-passthrough-refresh.service
~/.local/bin/linein-passthrough enable
```

Optional reserved WirePlumber config:

```bash
install -Dm0644 config/wireplumber/90-linein-passthrough.conf ~/.config/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf
systemctl --user restart wireplumber.service
```

## Everyday Use

```bash
linein-passthrough enable
linein-passthrough disable
linein-passthrough toggle
linein-passthrough status
linein-passthrough refresh
```

## Uninstall

```bash
make uninstall
```

To keep the optional WirePlumber placeholder config:

```bash
make uninstall-keep-wireplumber
```

Or directly:

```bash
~/.local/bin/linein-passthrough-uninstall --keep-wireplumber-config
```

## More Docs

- [Command reference](docs/usage.md)
- [Troubleshooting](docs/troubleshooting.md)
- [Design notes](docs/design.md)

## License

MIT
