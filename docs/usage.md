# Usage

## OCI Installer

Primary immutable-OS distribution is the OCI installer image:

```bash
ghcr.io/rosspeoples/linein-passthrough:latest
```

Preferred immutable references:

```bash
ghcr.io/rosspeoples/linein-passthrough:git-<shortsha>
ghcr.io/rosspeoples/linein-passthrough:sha256-<manifestdigest>
```

Install:

```bash
podman run --rm \
  --security-opt label=disable \
  --userns keep-id \
  -e HOME \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS \
  -v "$HOME:$HOME" \
  -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
  ghcr.io/rosspeoples/linein-passthrough:latest install
```

Install with optional WirePlumber placeholder config:

```bash
podman run --rm \
  --security-opt label=disable \
  --userns keep-id \
  -e HOME \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS \
  -v "$HOME:$HOME" \
  -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
  ghcr.io/rosspeoples/linein-passthrough:latest install --with-wireplumber-config
```

Uninstall:

```bash
podman run --rm \
  --security-opt label=disable \
  --userns keep-id \
  -e HOME \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS \
  -v "$HOME:$HOME" \
  -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
  ghcr.io/rosspeoples/linein-passthrough:latest uninstall
```

To keep the placeholder config:

```bash
podman run --rm \
  --security-opt label=disable \
  --userns keep-id \
  -e HOME \
  -e XDG_RUNTIME_DIR \
  -e DBUS_SESSION_BUS_ADDRESS \
  -v "$HOME:$HOME" \
  -v "$XDG_RUNTIME_DIR:$XDG_RUNTIME_DIR" \
  ghcr.io/rosspeoples/linein-passthrough:latest uninstall --keep-wireplumber-config
```

On SELinux-enforcing systems, `--security-opt label=disable` is required for these bind mounts.

If the container cannot reach your host user systemd bus, install still writes the files but may warn instead of reloading or restarting services from inside the container. Run this in the host session afterward if needed:

```bash
systemctl --user daemon-reload
systemctl --user restart pipewire.service wireplumber.service
```

## Commands

```bash
linein-passthrough enable
linein-passthrough disable
linein-passthrough toggle
linein-passthrough status
linein-passthrough refresh
```

## `enable`

- detects a likely line-in source node
- writes `~/.config/pipewire/pipewire.conf.d/90-linein-passthrough.conf`
- creates a virtual sink called `Line-In Passthrough`
- restarts `pipewire.service` and `wireplumber.service` if the config changed

## `disable`

- removes the generated loopback config
- clears saved state
- restarts user audio services

## `toggle`

- enables passthrough if it is currently disabled
- disables passthrough if it is currently enabled

## `status`

When enabled, prints:

- generated config path
- detected line-in node id
- detected line-in node name and nick when available
- virtual sink name and nick
- current output sink target

## `refresh`

- re-detects the line-in source
- re-detects the output sink
- rewrites the config only when the generated content changed

Use `refresh` after:

- changing audio profiles
- docking or undocking
- changing default speakers or headphones
- codec route changes

## Make Targets

```bash
make install
make install-wireplumber
make uninstall
make uninstall-keep-wireplumber
make status
make enable
make disable
make refresh
```
