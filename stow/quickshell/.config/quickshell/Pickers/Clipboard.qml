import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Clipboard history, stored by cliphist. Enter pastes into the focused window, Delete
// forgets an entry. Copies a password manager marks as sensitive never get recorded.
Scope {
  id: root

  property bool opened: false
  property var entries: []

  function refresh() {
    if (!lister.running) lister.running = true
  }

  // Keep recording for as long as the shell runs, and not a moment longer.
  Process {
    running: true
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "text", "--watch", "cliphist", "store"]
  }

  Process {
    running: true
    command: ["setpriv", "--pdeathsig", "TERM", "wl-paste", "--type", "image", "--watch", "cliphist", "store"]
  }

  Process {
    id: lister
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.entries = text.split("\n").filter(Boolean).map(function(line) {
          var tab = line.indexOf("\t")
          var body = line.substring(tab + 1)
          return {
            line: line,
            id: line.substring(0, tab),
            label: body.replace(/\s+/g, " ").trim() || "(blank)",
            icon: body.indexOf("[[ binary data") === 0 ? "\u{F02E9}" : "\u{F0147}"
          }
        })
      }
    }
  }

  Overlay {
    id: overlay

    shown: root.opened
    scrim: Theme.menu.scrim
    WlrLayershell.namespace: "desk-clipboard"
    onDismissed: root.opened = false

    ListCard {
      id: card

      anchors.horizontalCenter: parent.horizontalCenter
      cardWidth: Style.space(640)
      placeholder: "Clipboard"
      rows: {
        var query = filter.toLowerCase()
        var all = root.entries
        if (query) all = all.filter(function(entry) { return entry.label.toLowerCase().indexOf(query) !== -1 })
        return all.slice(0, 200)
      }

      onActivated: function(row) {
        root.opened = false
        Quickshell.execDetached(["clipboard-paste", row.id])
      }
      onDeleted: function(row) {
        root.entries = root.entries.filter(function(entry) { return entry !== row })
        Quickshell.execDetached(["bash", "-c", 'printf "%s\\n" "$1" | cliphist delete', "--", row.line])
      }
      onCancelled: root.opened = false
    }

    onShownChanged: if (shown) card.reset()
  }

  IpcHandler {
    target: "clipboard"

    function toggle(): void {
      root.opened = !root.opened
      if (root.opened) root.refresh()
    }
  }
}
