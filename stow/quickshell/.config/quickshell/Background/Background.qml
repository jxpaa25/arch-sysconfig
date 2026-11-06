import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// The desktop background: the chosen wallpaper, or the theme's background colour.
Variants {
  model: Quickshell.screens

  PanelWindow {
    id: window

    required property var modelData
    screen: modelData

    WlrLayershell.namespace: "desk-background"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    anchors { top: true; bottom: true; left: true; right: true }
    color: Theme.background

    Image {
      anchors.fill: parent
      visible: status === Image.Ready
      source: Saved.wallpaper ? "file://" + Saved.wallpaper : ""
      fillMode: Image.PreserveAspectCrop
      asynchronous: true
      cache: false
      sourceSize.width: window.width
      sourceSize.height: window.height
    }
  }
}
