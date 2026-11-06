import QtQuick
import qs.Commons
import qs.Ui

// A bar widget that opens a panel. A short mark under it shows while its panel is open.
BarButton {
  id: root

  required property string screenName
  required property string panelId

  // Registered per screen, so a hotkey opens the copy on the focused monitor.
  onScreenNameChanged: Panels.register(panelId, screenName, root)
  Component.onCompleted: Panels.register(panelId, screenName, root)
  Component.onDestruction: Panels.unregister(panelId, screenName, root)

  onClicked: function(button) {
    if (button === Qt.LeftButton) Panels.toggle(panelId, root)
  }

  Rectangle {
    anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter }
    width: Style.space(12)
    height: Math.max(1, Style.space(2))
    color: Theme.bar.text
    visible: Panels.current === root.panelId && Panels.anchor === root
  }
}
