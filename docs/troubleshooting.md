# Troubleshooting

## No Sound From Line-In

Run:

```bash
linein-passthrough status
linein-passthrough refresh
wpctl status
```

Check that:

- your motherboard input is exposed as a source node
- the correct input route or profile is selected for the audio device
- the line-in jack is not muted in ALSA or firmware
- the line-in source volume is not too high for your external device

## Wrong Source Was Chosen

Inspect available source nodes:

```bash
pw-dump | jq -r '.[]
  | select(.type == "PipeWire:Interface:Node")
  | select(.info.props["media.class"] == "Audio/Source")
  | [.id, .info.props["node.name"], .info.props["node.nick"], .info.props["node.description"]]
  | @tsv'
```

If your hardware does not match the default heuristics, adjust the detection logic in `libexec/linein-passthrough-refresh`.

## Audio Is Clipping Or Distorted

The helper sets a conservative default gain, but some devices still drive motherboard line-in too hot.

Lower the capture gain further:

```bash
wpctl status
wpctl set-volume <line-in-node-id> 0.20
```

`linein-passthrough status` prints the detected line-in node id.

## Default Recording Device Changed

This project does not explicitly change the default source.

Check the current defaults:

```bash
wpctl status
wpctl inspect @DEFAULT_AUDIO_SOURCE@
```

If needed, re-select your preferred microphone in KDE or with `wpctl set-default`.

## `Line-In Passthrough` Does Not Show In Plasma

Refresh the config and restart user audio services:

```bash
linein-passthrough refresh
systemctl --user restart pipewire.service wireplumber.service
```

Also check whether Plasma is hiding virtual devices in the volume panel.

## Audio Services Fail To Restart

Inspect user service state and logs:

```bash
systemctl --user status pipewire.service wireplumber.service linein-passthrough-refresh.service
journalctl --user -u pipewire.service -u wireplumber.service -u linein-passthrough-refresh.service --no-pager -n 200
```

## Speakers Changed Or You Docked/Undocked

Run:

```bash
linein-passthrough refresh
```

This rewrites the generated config if the detected line-in source or active output sink changed.
