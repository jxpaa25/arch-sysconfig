import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// The top bar, one per monitor. To reorder or remove widgets, edit the rows below.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property var modelData
    readonly property string screenName: modelData.name

    screen: modelData
    visible: !Saved.barHidden

    WlrLayershell.namespace: "desk-bar"
    WlrLayershell.layer: WlrLayer.Top
    anchors { top: true; left: true; right: true }
    implicitHeight: Style.bar.size
    color: Theme.bar.background

    HoverHandler { id: barHover }

    Rectangle {
      anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
      height: 1
      color: Theme.withAlpha(Theme.bar.text, 0.15)
    }

    Row {
      anchors { left: parent.left; top: parent.top; bottom: parent.bottom }

      MenuButton {}
      Workspaces {}
    }

    Row {
      anchors.centerIn: parent

      SystemUpdate {}
    }

    Row {
      anchors { right: parent.right; top: parent.top; bottom: parent.bottom }

      Indicators { barHovered: barHover.hovered }

      Stat { script: "cpu-usage"; interval: 3 }
      Stat { script: "mem-usage"; interval: 3 }
      Stat { script: "cpu-temp"; interval: 5 }
      Stat { script: "disk-usage"; arguments: ["/"]; interval: 30 }
      Stat { script: "disk-usage"; arguments: ["/home"]; interval: 30 }
      Stat { script: "network-ping"; interval: 5 }
      Stat { script: "network-ip"; interval: 30 }

      Tray {}
      BluetoothButton { screenName: window.screenName }
      NetworkButton { screenName: window.screenName }
      AudioButton { screenName: window.screenName }
      MonitorButton { screenName: window.screenName }
      PowerButton { screenName: window.screenName }
      KeyboardLayout {}
      Clock { screenName: window.screenName }
    }
  }
}
