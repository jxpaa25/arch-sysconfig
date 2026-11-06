import QtQuick
import qs.Commons
import qs.Ui

// Left click opens the main menu, right click a terminal.
BarButton {
  text: String.fromCodePoint(0xF303)
  fontSize: Style.bar.iconFont + 1
  fixedWidth: Style.bar.size - Style.space(8) + Style.space(15)

  onClicked: function(button) {
    if (button === Qt.RightButton) Run.app("xdg-terminal-exec")
    else Run.sh("qs ipc call menu toggle root")
  }
}
