.pragma library

// The menu tree. Each menu has a title and rows. A row runs `action` (a shell command) or
// opens `menu`. `when` hides a row unless its shell test passes, `checked` marks it with a
// tick. Rows typed in the search box match across every menu here, plus the installed apps.

var laptop = "compgen -G '/sys/class/power_supply/BAT*' >/dev/null"
var stayAwake = "grep -q '\"stayAwake\": true' ~/.local/state/desk/shell.json"
var silenced = "grep -q '\"doNotDisturb\": true' ~/.local/state/desk/shell.json"
var nightLight = "grep -q '\"nightLight\": true' ~/.local/state/desk/shell.json"
var recording = "pgrep -x gpu-screen-recorder >/dev/null"
var toggles = "$HOME/.local/state/desk/toggles"

var menus = {
  root: {
    title: "Search",
    rows: [
      { label: "Apps", menu: "apps" },
      { label: "Keybindings", menu: "keybindings" },
      { label: "Appearance", menu: "appearance" },
      { label: "Tools", menu: "tools" },
      { label: "Update", menu: "update" },
      { label: "System", menu: "system" }
    ]
  },
  keybindings: {
    title: "Keybindings",
    rows: [
      { label: "Hyprland", action: "keybindings hyprland" },
      { label: "Tmux", action: "keybindings tmux" },
      { label: "Herdr", action: "keybindings herdr" }
    ]
  },
  appearance: {
    title: "Appearance",
    rows: [
      { label: "Theme", menu: "theme" },
      { label: "Background", action: "qs ipc call wallpaper toggle" },
      { label: "Hide or show the bar", action: "qs ipc call shell toggleBar" }
    ]
  },
  // Filled from the themes folder when the shell starts.
  theme: { title: "Theme", rows: [] },
  tools: {
    title: "Tools",
    rows: [
      { label: "Capture", menu: "capture" },
      { label: "Toggle", menu: "toggle" },
      { label: "Clipboard", action: "qs ipc call clipboard toggle" },
      { label: "Emoji", action: "qs ipc call emoji toggle" },
      { label: "Hardware", menu: "hardware" }
    ]
  },
  capture: {
    title: "Capture",
    rows: [
      { label: "Screenshot", action: "screenshot" },
      { label: "Stop recording", when: recording, action: "screen-record" },
      { label: "Record, no audio", when: "! " + recording, action: "screen-record" },
      { label: "Record with desktop audio", when: "! " + recording, action: "screen-record --desktop" },
      { label: "Record with desktop and microphone", when: "! " + recording, action: "screen-record --desktop --mic" },
      { label: "Text from screenshot", action: "capture-text" },
      { label: "Color", action: "pkill hyprpicker || hyprpicker -a" }
    ]
  },
  toggle: {
    title: "Toggle",
    rows: [
      { label: "Stay awake", checked: stayAwake, action: "qs ipc call idle toggleStayAwake" },
      { label: "Silence notifications", checked: silenced, action: "qs ipc call notifications toggleSilence" },
      { label: "Night light", checked: nightLight, action: "qs ipc call status nightLight" }
    ]
  },
  hardware: {
    title: "Hardware",
    rows: [
      { label: "Laptop display", when: laptop, checked: "[[ ! -f " + toggles + "/internal-monitor-disable.lua ]]", action: "monitor-internal toggle" },
      { label: "Mirror displays", when: laptop, checked: "[[ -f " + toggles + "/internal-monitor-mirror.lua ]]", action: "monitor-internal mirror" },
      { label: "Touchpad", when: laptop, checked: "[[ ! -f " + toggles + "/touchpad-disabled-name ]]", action: "toggle-touchpad" },
      { label: "Bluetooth devices", when: "command -v bluetui >/dev/null", action: "launch-tui bluetui" },
      { label: "Activity", action: "launch-tui btop" }
    ]
  },
  update: {
    title: "Update",
    rows: [
      { label: "Packages", action: "launch-tui --app-id=org.desk.update bash -c 'yay -Syu; echo; read -rsn1 -p \"Done. Press any key to close.\"'" },
      { label: "Restart the shell", action: "systemctl --user restart desk-shell.service" },
      { label: "Restart Wi-Fi", when: "compgen -G '/sys/class/net/wl*' >/dev/null", action: "nmcli radio wifi off; sleep 1; nmcli radio wifi on" },
      { label: "Password", action: "launch-tui --app-id=org.desk.update passwd" }
    ]
  },
  system: {
    title: "System",
    rows: [
      { label: "Screensaver", action: "qs ipc call idle screensaver" },
      { label: "Lock", action: "qs ipc call lock lock" },
      { label: "Suspend", action: "systemctl suspend" },
      { label: "Log out", action: "uwsm stop" },
      { label: "Reboot", action: "systemctl reboot" },
      { label: "Shutdown", action: "systemctl poweroff" }
    ]
  }
}

// Higher is better. 0 means no match.
function score(text, query) {
  var t = String(text || "").toLowerCase()
  var q = String(query).toLowerCase()
  if (!t || !q) return 0
  if (t === q) return 100
  if (t.indexOf(q) === 0) return 90
  var at = t.indexOf(q)
  if (at > 0) return /[\s\-_./]/.test(t.charAt(at - 1)) ? 70 : 50
  // Letters in order, with gaps.
  var i = 0
  for (var c = 0; c < t.length && i < q.length; c++) {
    if (t.charAt(c) === q.charAt(i)) i++
  }
  return i === q.length ? 20 : 0
}

function bestScore(row, query) {
  var best = score(row.label, query)
  var extra = row.search || []
  for (var i = 0; i < extra.length; i++) best = Math.max(best, score(extra[i], query) - 10)
  return best
}

function ranked(rows, query) {
  return rows
    .map(function (row) { return { row: row, score: bestScore(row, query) } })
    .filter(function (entry) { return entry.score > 0 })
    .sort(function (a, b) {
      return b.score - a.score || (a.row.label < b.row.label ? -1 : 1)
    })
    .map(function (entry) { return entry.row })
}

// Rows in every menu with something to run, labelled with where they live.
function flatten() {
  var out = []
  for (var id in menus) {
    if (id === "root") continue
    var title = menus[id].title
    menus[id].rows.forEach(function (row) {
      if (!row.action) return
      out.push(Object.assign({}, row, { detail: title, sourceMenu: id }))
    })
  }
  return out
}
