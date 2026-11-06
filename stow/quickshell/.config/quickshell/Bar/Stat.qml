import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// A dim readout fed by a small script. The script prints {"text": ..., "tooltip": ...},
// or nothing at all to hide itself.
BarButton {
  id: root

  required property string script
  property var arguments: []
  property int interval: 5

  visible: text !== ""
  width: visible ? implicitWidth : 0
  fontSize: 10
  margin: Style.spaceReal(7.5)
  labelOpacity: 0.4

  Process {
    id: proc
    command: [Quickshell.shellPath("scripts/" + root.script)].concat(root.arguments)
    stdout: StdioCollector {
      onStreamFinished: {
        var raw = text.trim()
        if (!raw) {
          root.text = ""
          return
        }
        try {
          var parsed = JSON.parse(raw)
          root.text = parsed.text || ""
          root.tooltip = parsed.tooltip || ""
        } catch (e) {
          root.text = raw
        }
      }
    }
  }

  Timer {
    interval: root.interval * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!proc.running) proc.running = true
  }
}
