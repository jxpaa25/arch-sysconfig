import QtQuick
import qs.Commons
import qs.Ui

// Left click opens the main menu, right click a terminal.
BarButton {
  text: "■"
  fontSize: Style.font.small
  fixedWidth: Style.space(26)

  onClicked: function(button) {
    if (button === Qt.RightButton) Run.app("xdg-terminal-exec")
    else Run.sh("qs ipc call menu toggle root")
  }
}
