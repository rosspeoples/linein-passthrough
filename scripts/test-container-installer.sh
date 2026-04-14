#!/usr/bin/env bash

set -euo pipefail

image_tag="${1:-localhost/linein-passthrough:test}"
test_home="$(mktemp -d)"
runtime_dir="${test_home}/runtime"
config_home="${test_home}/.config"
state_home="${test_home}/.local/state"
bin_dir="${test_home}/.local/bin"

cleanup() {
  rm -rf "${test_home}"
}
trap cleanup EXIT

mkdir -p "${runtime_dir}" "${config_home}" "${state_home}" "${bin_dir}" \
  "${config_home}/systemd/user" "${config_home}/pipewire/pipewire.conf.d" "${config_home}/wireplumber/wireplumber.conf.d"

cat > "${bin_dir}/systemctl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${bin_dir}/systemctl"

cat > "${bin_dir}/wpctl" <<'EOF'
#!/usr/bin/env bash
if [[ "$1" == "inspect" && "$2" == "@DEFAULT_AUDIO_SINK@" ]]; then
  printf 'node.name = "alsa_output.pci-0000_00_1f.3.analog-stereo"\n'
  exit 0
fi
printf 'mock wpctl unsupported\n' >&2
exit 1
EOF
chmod +x "${bin_dir}/wpctl"

cat > "${bin_dir}/pw-dump" <<'EOF'
#!/usr/bin/env bash
cat <<'JSON'
[
  {
    "id": 50,
    "type": "PipeWire:Interface:Device",
    "info": {
      "params": {
        "Route": [
          {
            "direction": "Input",
            "name": "Line In",
            "description": "Line In",
            "available": "yes"
          }
        ]
      }
    }
  },
  {
    "id": 101,
    "type": "PipeWire:Interface:Node",
    "info": {
      "props": {
        "node.name": "alsa_input.pci-0000_00_1f.3.analog-stereo",
        "node.nick": "Line In",
        "node.description": "Built-in Audio Line In",
        "media.class": "Audio/Source",
        "device.id": 50,
        "object.path": "alsa:pcm:0:capture",
        "device.api": "alsa"
      }
    }
  },
  {
    "id": 201,
    "type": "PipeWire:Interface:Node",
    "info": {
      "props": {
        "node.name": "alsa_output.pci-0000_00_1f.3.analog-stereo",
        "node.description": "Built-in Audio Analog Stereo",
        "media.class": "Audio/Sink"
      }
    }
  }
]
JSON
EOF
chmod +x "${bin_dir}/pw-dump"

cat > "${bin_dir}/pactl" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
chmod +x "${bin_dir}/pactl"

podman build -f Containerfile -t "${image_tag}" .

podman run --rm \
  --userns keep-id \
  -e HOME="${test_home}" \
  -e PATH="${bin_dir}:/usr/bin:/bin" \
  -e XDG_CONFIG_HOME="${config_home}" \
  -e XDG_STATE_HOME="${state_home}" \
  -e XDG_RUNTIME_DIR="${runtime_dir}" \
  -v "${test_home}:${test_home}:Z" \
  "${image_tag}" install --with-wireplumber-config

test -x "${bin_dir}/linein-passthrough"
test -x "${bin_dir}/linein-passthrough-refresh"
test -x "${bin_dir}/linein-passthrough-uninstall"
test -f "${config_home}/systemd/user/linein-passthrough-refresh.service"
test -f "${config_home}/pipewire/pipewire.conf.d/90-linein-passthrough.conf"
test -f "${config_home}/pipewire/pipewire.conf.d/90-linein-passthrough.conf.disabled"
test -f "${config_home}/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf"

podman run --rm \
  --userns keep-id \
  -e HOME="${test_home}" \
  -e PATH="${bin_dir}:/usr/bin:/bin" \
  -e XDG_CONFIG_HOME="${config_home}" \
  -e XDG_STATE_HOME="${state_home}" \
  -e XDG_RUNTIME_DIR="${runtime_dir}" \
  -v "${test_home}:${test_home}:Z" \
  "${image_tag}" uninstall --keep-wireplumber-config

test ! -f "${bin_dir}/linein-passthrough"
test ! -f "${config_home}/pipewire/pipewire.conf.d/90-linein-passthrough.conf"
test -f "${config_home}/wireplumber/wireplumber.conf.d/90-linein-passthrough.conf"

printf 'container installer test passed for %s\n' "${image_tag}"
