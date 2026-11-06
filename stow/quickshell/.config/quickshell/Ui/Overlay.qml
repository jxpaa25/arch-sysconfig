import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

// A full-screen layer on the focused monitor that takes the keyboard while it's open.
// Everything summoned by a hotkey (menu, pickers, panels) sits on one of these.
// Set `shown`. Clicks outside whatever the content claims emit `dismissed`.
PanelWindow {
  id: root

  property bool shown: false
  property color scrim: "transparent"
  property var targetScreen: null

  signal dismissed

  onShownChanged: if (shown) targetScreen = Panels.screenByName(Panels.focusedScreenName())

  screen: targetScreen
  visible: shown && targetScreen !== null
  color: "transparent"
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  Rectangle {
    anchors.fill: parent
    color: root.scrim
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
    onClicked: root.dismissed()
  }
}
