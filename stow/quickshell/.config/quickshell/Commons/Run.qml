pragma Singleton
import QtQuick
import Quickshell

// Starting things from the shell.
Singleton {
  function quote(value) {
    return "'" + String(value).replace(/'/g, "'\\''") + "'"
  }

  // A short-lived shell command, fire and forget.
  function sh(command) {
    Quickshell.execDetached(["bash", "-c", command])
  }

  // An app that outlives the click. It gets its own systemd unit, so a shell restart
  // doesn't take it down and uwsm can clean it up with the session.
  function app(command) {
    Quickshell.execDetached(["uwsm-app", "--", "bash", "-c", command])
  }

  // A TUI in its own floating terminal, focusing it if it's already open.
  function tui(command) {
    Quickshell.execDetached(["launch-tui"].concat(String(command).split(" ")))
  }

  // Run Lua inside Hyprland. Config helpers such as grouped_workspaces live there.
  function hypr(lua) {
    Quickshell.execDetached(["hyprctl", "eval", lua])
  }

  function notify(summary, body) {
    Quickshell.execDetached(["notify-send", "-a", "Desktop", String(summary), String(body || "")])
  }
}
