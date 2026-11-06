import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Shows up when pacman or the AUR has updates. Click to run them in a terminal.
BarButton {
  id: root

  property int count: 0

  visible: count > 0
  width: visible ? implicitWidth : 0
  text: String.fromCodePoint(0xF021)
  tooltip: count + (count === 1 ? " update available" : " updates available")
  fontSize: Style.font.caption
  active: true

  onClicked: {
    Quickshell.execDetached(["launch-tui", "--app-id=org.desk.update", "bash", "-c", "yay -Syu; echo; read -rsn1 -p 'Done. Press any key to close.'"])
    count = 0
  }

  Process {
    id: check
    command: ["bash", "-c", "{ checkupdates --nocolor 2>/dev/null; yay -Qua 2>/dev/null; } | grep -c ."]
    stdout: StdioCollector {
      onStreamFinished: root.count = parseInt(text) || 0
    }
  }

  Timer {
    interval: 6 * 60 * 60 * 1000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: if (!check.running) check.running = true
  }
}
