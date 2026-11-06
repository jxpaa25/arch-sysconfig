import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Hosts whichever panel is open, in a card under its bar widget. The layer starts below the
// bar, so the bar stays clickable and a click on another widget hands over to its panel.
Overlay {
  id: root

  readonly property var sources: ({
    audio: "AudioPanel.qml",
    network: "NetworkPanel.qml",
    bluetooth: "BluetoothPanel.qml",
    monitor: "MonitorPanel.qml",
    power: "PowerPanel.qml",
    clock: "CalendarPanel.qml",
    worldclock: "WorldClockPanel.qml"
  })

  shown: Panels.current !== ""
  fixedScreen: Panels.screen
  margins.top: Saved.barHidden ? 0 : Style.bar.size
  WlrLayershell.namespace: "desk-panel"
  onDismissed: Panels.close()
  onShownChanged: if (shown) keys.forceActiveFocus()

  readonly property real anchorCenter: {
    var item = Panels.anchor
    if (!item) return width / 2
    return item.mapToItem(null, item.width / 2, 0).x
  }

  Rectangle {
    id: card

    x: Math.max(Style.edgeGap, Math.min(root.width - width - Style.edgeGap, root.anchorCenter - width / 2))
    y: Style.spacing.xs
    width: loader.item ? loader.item.implicitWidth : 0
    height: Math.min(loader.item ? loader.item.implicitHeight : 0, root.height - Style.edgeGap * 2)
    color: Theme.popup.background
    border.color: Theme.popup.border
    border.width: Style.border
    radius: Style.radius

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.AllButtons
    }

    Loader {
      id: loader
      anchors.fill: parent
      active: Panels.current !== ""
      source: active ? root.sources[Panels.current] : ""
    }
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true

    Keys.onPressed: function(event) {
      switch (event.key) {
      case Qt.Key_Escape:
        Panels.close()
        break
      case Qt.Key_Tab:
        Panels.step(1)
        break
      case Qt.Key_Backtab:
        Panels.step(-1)
        break
      default:
        if (!loader.item || !loader.item.handleKey(event)) return
      }
      event.accepted = true
    }
  }
}
