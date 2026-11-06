.pragma library

// The menu tree. Each menu has a title and rows. A row runs `action` (a shell command) or
// opens `menu`. `when` hides a row unless its shell test passes, `checked` marks it with a
// tick. Rows typed in the search box match across every menu here, plus the installed apps.

var laptop = "compgen -G '/sys/class/power_supply/BAT*' >/dev/null"
var stayAwake = "grep -q '\"stayAwake\": true' ~/.local/state/desk/shell.json"
var silenced = "grep -q '\"doNotDisturb\": true' ~/.local/state/desk/shell.json"
var nightLight = "grep -q '\"nightLight\": true' ~/.local/state/desk/shell.json"
var recording = "pgrep -x gpu-screen-recorder >/dev/null"
var localsend = "command -v localsend >/dev/null"
var toggles = "$HOME/.local/state/desk/toggles"

var menus = {
  root: {
    title: "Go",
    rows: [
      { icon: "\u{F003B}", label: "Apps", menu: "apps" },
      { icon: "\u{F0AC2}", label: "Keybindings", menu: "keybindings" },
      { icon: "\u{F03D8}", label: "Appearance", menu: "appearance" },
      { icon: "\u{F14DE}", label: "Trigger", menu: "trigger" },
      { icon: "", label: "Update", menu: "update" },
      { icon: "", label: "System", menu: "system" }
    ]
  },
  keybindings: {
    title: "Keybindings",
    rows: [
      { icon: "", label: "Hyprland", action: "keybindings hyprland" },
      { icon: "", label: "Tmux", action: "keybindings tmux" },
      { icon: "", label: "Herdr", action: "keybindings herdr" }
    ]
  },
  appearance: {
    title: "Appearance",
    rows: [
      { icon: "\u{F0E0C}", label: "Theme", menu: "theme" },
      { icon: "", label: "Background", action: "qs ipc call wallpaper toggle" },
      { icon: "\u{F0209}", label: "Hide or show the bar", action: "qs ipc call shell toggleBar" }
    ]
  },
  // Filled from the themes folder when the shell starts.
  theme: { title: "Theme", rows: [] },
  trigger: {
    title: "Trigger",
    rows: [
      { icon: "", label: "Capture", menu: "capture" },
      { icon: "\u{F050E}", label: "Toggle", menu: "toggle" },
      { icon: "", label: "Share", menu: "share" },
      { icon: "\u{F0147}", label: "Clipboard", action: "qs ipc call clipboard toggle" },
      { icon: "\u{F0785}", label: "Emoji", action: "qs ipc call emoji toggle" },
      { icon: "", label: "Hardware", menu: "hardware" }
    ]
  },
  capture: {
    title: "Capture",
    rows: [
      { icon: "", label: "Screenshot", action: "screenshot" },
      { icon: "", label: "Stop recording", when: recording, action: "screen-record" },
      { icon: "\u{F044B}", label: "Record, no audio", when: "! " + recording, action: "screen-record" },
      { icon: "\u{F044B}", label: "Record with desktop audio", when: "! " + recording, action: "screen-record --desktop" },
      { icon: "\u{F044B}", label: "Record with desktop and microphone", when: "! " + recording, action: "screen-record --desktop --mic" },
      { icon: "\u{F0D11}", label: "Text from screenshot", action: "capture-text" },
      { icon: "\u{F0449}", label: "Color", action: "pkill hyprpicker || hyprpicker -a" }
    ]
  },
  toggle: {
    title: "Toggle",
    rows: [
      { icon: "\u{F0176}", label: "Stay awake", checked: stayAwake, action: "qs ipc call idle toggleStayAwake" },
      { icon: "\u{F009B}", label: "Silence notifications", checked: silenced, action: "qs ipc call notifications toggleSilence" },
      { icon: "\u{F050E}", label: "Night light", checked: nightLight, action: "qs ipc call status nightLight" }
    ]
  },
  share: {
    title: "Share",
    rows: [
      { icon: "\uf0c5", label: "Clipboard", when: localsend, action: "share-send clipboard" },
      { icon: "\uf15b", label: "File", when: localsend, action: "share-send file" },
      { icon: "\uf07b", label: "Folder", when: localsend, action: "share-send folder" },
      { icon: "\u{F0966}", label: "Receive", when: localsend, action: "uwsm-app -- localsend" }
    ]
  },
  hardware: {
    title: "Hardware",
    rows: [
      { icon: "\u{F06A7}", label: "Laptop display", when: laptop, checked: "[[ ! -f " + toggles + "/internal-monitor-disable.lua ]]", action: "monitor-internal toggle" },
      { icon: "\u{F0379}", label: "Mirror displays", when: laptop, checked: "[[ -f " + toggles + "/internal-monitor-mirror.lua ]]", action: "monitor-internal mirror" },
      { icon: "\u{F07D8}", label: "Touchpad", when: laptop, checked: "[[ ! -f " + toggles + "/touchpad-disabled-name ]]", action: "toggle-touchpad" },
      { icon: "", label: "Bluetooth devices", when: "command -v bluetui >/dev/null", action: "launch-tui bluetui" },
      { icon: "", label: "Activity", action: "launch-tui btop" }
    ]
  },
  update: {
    title: "Update",
    rows: [
      { icon: "\u{F03D6}", label: "Packages", action: "launch-tui --app-id=org.desk.update bash -c 'yay -Syu; echo; read -rsn1 -p \"Done. Press any key to close.\"'" },
      { icon: "\u{F0709}", label: "Restart the shell", action: "systemctl --user restart desk-shell.service" },
      { icon: "", label: "Restart Wi-Fi", when: "compgen -G '/sys/class/net/wl*' >/dev/null", action: "nmcli radio wifi off; sleep 1; nmcli radio wifi on" },
      { icon: "", label: "Password", action: "launch-tui --app-id=org.desk.update passwd" }
    ]
  },
  system: {
    title: "System",
    rows: [
      { icon: "\u{F1104}", label: "Screensaver", action: "qs ipc call idle screensaver" },
      { icon: "", label: "Lock", action: "qs ipc call lock lock" },
      { icon: "\u{F04B2}", label: "Suspend", action: "systemctl suspend" },
      { icon: "\u{F0343}", label: "Log out", action: "uwsm stop" },
      { icon: "\u{F0709}", label: "Reboot", action: "systemctl reboot" },
      { icon: "\u{F0425}", label: "Shutdown", action: "systemctl poweroff" }
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
