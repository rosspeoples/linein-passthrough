# Usage

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
