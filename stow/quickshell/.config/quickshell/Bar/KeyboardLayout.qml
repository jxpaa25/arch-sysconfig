import QtQuick
import Quickshell.Hyprland
import Quickshell.Io
import qs.Commons
import qs.Ui

// The active keyboard layout. Click to move to the next one. Hidden with a single layout.
BarButton {
  id: root

  property string layout: ""
  property string keyboard: ""
  property bool multiple: false

  // Both Serbian scripts share a language code, so they get their own labels.
  readonly property var labels: ({
    "English (US)": "EN",
    "Serbian (Latin)": "LAT",
    "Serbian": "ЋИР"
  })

  // Devices that report layouts but that nobody types on. They can hold the "main" flag,
  // so reading them would describe a power button.
  readonly property var notTyped: /^(hl-virtual-keyboard|power-button|sleep-button|lid-switch|video-bus)/

  visible: multiple && layout !== ""
  width: visible ? implicitWidth : 0
  text: labels[layout] || layout.substring(0, 3).toUpperCase()
  tooltip: layout
  fontSize: Style.font.caption
  margin: Style.spaceReal(6)

  onClicked: {
    if (!keyboard) return
    Run.sh("hyprctl switchxkblayout " + Run.quote(keyboard) + " next")
  }

  function refresh() {
    if (query.running) again.restart()
    else query.running = true
  }

  Component.onCompleted: refresh()

  // The event fires as the switch happens, so a query already running may read the old one.
  Timer { id: again; interval: 200; onTriggered: root.refresh() }

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      var name = String(event.name)
      if (name === "activelayout" || name === "configreloaded") root.refresh()
    }
  }

  Process {
    id: query
    command: ["hyprctl", "-j", "devices"]
    stdout: StdioCollector {
      onStreamFinished: {
        var listed
        try {
          listed = JSON.parse(text).keyboards
        } catch (e) {
          return
        }
        var typed = listed.filter(function(k) { return !root.notTyped.test(k.name) })
        // Only the keyboard being typed on advances, so the furthest along is the one to read.
        var best = typed.reduce(function(a, b) {
          return (b.active_layout_index || 0) > (a.active_layout_index || 0) ? b : a
        }, typed[0])
        if (!best) return
        root.keyboard = best.name
        root.layout = best.active_keymap
        root.multiple = String(best.layout).indexOf(",") !== -1
      }
    }
  }
}
