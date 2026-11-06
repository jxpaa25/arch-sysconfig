import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Search for an emoji and type it into the focused window.
Scope {
  id: root

  property bool opened: false
  property var emojis: []

  FileView {
    path: Quickshell.shellPath("Pickers/emojis.json")
    onLoaded: {
      root.emojis = JSON.parse(text()).map(function(entry) {
        return { icon: entry.e, label: entry.k, emoji: entry.e }
      })
    }
  }

  Overlay {
    id: overlay

    shown: root.opened
    scrim: Theme.menu.scrim
    WlrLayershell.namespace: "desk-emoji"
    onDismissed: root.opened = false

    ListCard {
      id: card

      anchors.horizontalCenter: parent.horizontalCenter
      placeholder: "Emoji"
      rows: {
        var words = filter.toLowerCase().split(/\s+/).filter(Boolean)
        var all = root.emojis
        if (words.length) {
          all = all.filter(function(entry) {
            return words.every(function(word) { return entry.label.indexOf(word) !== -1 })
          })
        }
        return all.slice(0, 200)
      }

      onActivated: function(row) {
        root.opened = false
        Quickshell.execDetached(["type-into-window", row.emoji])
      }
      onCancelled: root.opened = false
    }

    onShownChanged: if (shown) card.reset()
  }

  IpcHandler {
    target: "emoji"

    function toggle(): void { root.opened = !root.opened }
  }
}
