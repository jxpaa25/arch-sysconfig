#!/usr/bin/env bash
# Check a finished install. Needs no root and changes nothing, apart from switching the theme
# away and back when it runs inside a desktop session.
#
#   tests/verify.sh    prints PASS, FAIL or SKIP per check, and exits 1 if anything failed
#
# Run it from the desktop for the full set. Without a session, those checks show as SKIP.
set -uo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
config="${XDG_CONFIG_HOME:-$HOME/.config}"
failed=0
passed=0
skipped=0

pass() {
  printf 'PASS  %s\n' "$1"
  passed=$((passed + 1))
}
fail() {
  printf 'FAIL  %s: %s\n' "$1" "$2"
  failed=$((failed + 1))
}
skip() {
  printf 'SKIP  %s: %s\n' "$1" "$2"
  skipped=$((skipped + 1))
}
same() {
  if [[ $2 == "$3" ]]; then pass "$1"; else fail "$1" "expected [$3], got [$2]"; fi
}

list() {
  sed -E 's/#.*//; s/[[:space:]]+//g; /^$/d' "$repo/packages/$1.txt"
}

check_list() {
  local missing
  missing="$(list "$1" | while read -r pkg; do pacman -Qq "$pkg" >/dev/null 2>&1 || echo "$pkg"; done | xargs)"
  if [[ -z $missing ]]; then pass "Packages: $1"; else fail "Packages: $1" "missing $missing"; fi
}

echo '--- Packages'
for name in base gpu-common desktop cli dev security apps aur; do
  check_list "$name"
done
if command -v yay >/dev/null; then pass 'AUR helper'; else fail 'AUR helper' 'yay not found'; fi

# The same detection as install/20-drivers.sh.
for dev in /sys/bus/pci/devices/*; do
  [[ $(<"$dev/class") == 0x03* ]] || continue
  case "$(<"$dev/vendor")" in
    0x8086) gpu="gpu-intel" ;;
    0x1002) gpu="gpu-amd" ;;
    0x10de) gpu="gpu-nvidia" ;;
    *) continue ;;
  esac
  check_list "$gpu"
done
virt="$(systemd-detect-virt 2>/dev/null || true)"
case "$virt" in
  none)
    check_list hardware
    case "$(awk -F': ' '/^vendor_id/ { print $2; exit }' /proc/cpuinfo)" in
      GenuineIntel) check_list cpu-intel ;;
      AuthenticAMD) check_list cpu-amd ;;
    esac
    ;;
  kvm | qemu) check_list vm-qemu ;;
esac

snapshots=0
if [[ $(findmnt -no FSTYPE /) == btrfs ]] && pacman -Qq limine >/dev/null 2>&1; then
  snapshots=1
  check_list snapshots
  check_list aur-snapshots
fi

echo '--- System'
units=(NetworkManager.service fstrim.timer systemd-timesyncd.service systemd-oomd.service
  systemd-resolved.service docker.service bluetooth.service ufw.service)
((snapshots)) && units+=(snapper-cleanup.timer limine-snapper-sync.service)
for unit in "${units[@]}"; do
  same "Enabled: $unit" "$(systemctl is-enabled "$unit" 2>/dev/null)" enabled
done
same 'Login shell is zsh' "$(getent passwd "$USER" | cut -d: -f7)" /usr/bin/zsh
if id -nG "$USER" | grep -qw docker; then pass 'In the docker group'; else fail 'In the docker group' "$(id -nG "$USER")"; fi
same 'DNS goes through resolved' "$(readlink /etc/resolv.conf)" /run/systemd/resolve/stub-resolv.conf
if swapon --show=NAME --noheadings | grep -q zram; then pass 'zram is on'; else fail 'zram is on' 'no zram swap'; fi

echo '--- Dotfiles'
bad=""
while IFS= read -r -d '' file; do
  pkg_dir="${file#"$repo/stow/"}"
  rel="${pkg_dir#*/}"
  [[ $HOME/$rel -ef $file ]] || bad+=" ~/$rel"
done < <(find "$repo/stow" -type f -print0)
if [[ -z $bad ]]; then pass 'Every dotfile is linked'; else fail 'Every dotfile is linked' "not linked:$bad"; fi
same 'Themes are linked' "$(readlink "$HOME/.local/share/desk/themes")" "$repo/themes"
if [[ -e $HOME/.local/state/theme/current/colors.toml ]]; then
  pass 'A theme is selected'
else
  fail 'A theme is selected' "no colors.toml in ~/.local/state/theme/current"
fi
if [[ -e $HOME/.local/src/hyprexpo/hyprexpo.so ]]; then
  pass 'hyprexpo is built'
else
  skip 'hyprexpo is built' 'optional. Retry with hyprexpo-rebuild'
fi

echo '--- Default apps'
same 'Browser' "$(xdg-settings get default-web-browser 2>/dev/null)" zen.desktop
same 'Web links' "$(xdg-mime query default x-scheme-handler/https 2>/dev/null)" zen.desktop
same 'Terminal' "$(grep -v '^#' "$config/xdg-terminals.list" 2>/dev/null | head -n1)" com.mitchellh.ghostty.desktop
same 'Editor' "$(zsh -c 'printf %s "$EDITOR"' 2>/dev/null)" helix

echo '--- No Omarchy'
hits="$(cd "$repo" && grep -rIli omarchy stow install themes templates packages system 2>/dev/null | xargs)"
if [[ -z $hits ]]; then pass 'None in the config'; else fail 'None in the config' "$hits"; fi
hits="$(pacman -Qq 2>/dev/null | grep -i omarchy | xargs)"
if [[ -z $hits ]]; then pass 'None installed'; else fail 'None installed' "$hits"; fi
if [[ -e /usr/share/omarchy ]]; then fail 'No /usr/share/omarchy' 'it exists'; else pass 'No /usr/share/omarchy'; fi

clean_tree() {
  if ! git -C "$repo" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    skip "$1" 'not a git checkout'
    return
  fi
  same "$1" "$(git -C "$repo" status --porcelain | xargs)" ''
}

echo '--- This repo'
clean_tree 'The install left tracked files alone'

echo '--- Desktop session'
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
HYPRLAND_INSTANCE_SIGNATURE="$(find "$XDG_RUNTIME_DIR/hypr" -mindepth 1 -maxdepth 1 -printf '%T@ %f\n' 2>/dev/null | sort -rn | head -n1 | cut -d' ' -f2)"
if [[ -z $HYPRLAND_INSTANCE_SIGNATURE ]] || ! HYPRLAND_INSTANCE_SIGNATURE=$HYPRLAND_INSTANCE_SIGNATURE hyprctl version >/dev/null 2>&1; then
  skip 'Session checks' 'Hyprland is not running'
else
  export HYPRLAND_INSTANCE_SIGNATURE
  # qs prints a warning into its output when no locale is set, as over SSH.
  export LANG="${LANG:-C.UTF-8}"
  socket="$(find "$XDG_RUNTIME_DIR" -maxdepth 1 -type s -name 'wayland-*' -printf '%f\n' | sort | head -n1)"
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-$socket}"

  same 'Hyprland runs under uwsm' "$(systemctl --user is-active wayland-wm@hyprland.desktop.service)" active
  same 'Shell service' "$(systemctl --user is-active desk-shell.service)" active
  same 'Shell answers' "$(qs ipc call shell ping 2>/dev/null)" pong
  same 'Hyprland config has no errors' "$(hyprctl configerrors | grep -c .)" 0
  layers="$(hyprctl layers -j | jq -r '[.[].levels | to_entries[].value[].namespace] | unique | join(",")')"
  if [[ ,$layers, == *,desk-background,* && (,$layers, == *,desk-bar,* || $(qs ipc call shell barHidden) == true) ]]; then
    pass 'Bar and background are up'
  else
    fail 'Bar and background are up' "layers: $layers"
  fi
  same 'No failed user units' "$(systemctl --user --failed --no-legend | wc -l)" 0
  same 'No failed system units' "$(systemctl --failed --no-legend | wc -l)" 0

  # Warnings about hardware a machine doesn't have, or from Qt itself, aren't ours to fix.
  errors="$(journalctl --user -u desk-shell.service -b --no-pager -o cat |
    grep -E 'WARN|ERROR' | grep -vE 'qpa\.services|org\.bluez|textinput|fileview' | cut -c1-160 | head -n5)"
  same 'Shell log is clean' "$errors" ''

  if wpctl status 2>/dev/null | grep -q 'Audio'; then pass 'PipeWire answers'; else fail 'PipeWire answers' 'wpctl has no audio section'; fi

  # Theme switching must never touch a tracked file.
  current="$(basename "$(readlink "$HOME/.local/state/theme/current")")"
  other=ultrawhite
  [[ $current == ultrawhite ]] && other=vantablack
  theme-set "$other" >/dev/null 2>&1
  same 'Theme switches' "$(basename "$(readlink "$HOME/.local/state/theme/current")")" "$other"
  clean_tree 'Switching theme left tracked files alone'
  theme-set "$current" >/dev/null 2>&1
  same 'Theme switches back' "$(basename "$(readlink "$HOME/.local/state/theme/current")")" "$current"
  clean_tree 'Switching back left tracked files alone'
fi

printf '\n%d passed, %d failed, %d skipped\n' "$passed" "$failed" "$skipped"
((failed == 0))
