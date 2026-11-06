import QtQuick
import Quickshell
import qs.Commons

// A hover tooltip. The popup only exists while it's showing.
Item {
  id: root

  required property Item target
  property string text: ""
  property bool shown: false
  property int edge: Edges.Bottom

  property bool settled: false

  onShownChanged: {
    if (shown) delay.restart()
    else {
      delay.stop()
      settled = false
    }
  }

  Timer {
    id: delay
    interval: 400
    onTriggered: root.settled = true
  }

  Loader {
    active: root.settled && root.text !== "" && root.target.QsWindow.window !== null

    sourceComponent: PopupWindow {
      visible: true
      color: "transparent"
      anchor.item: root.target
      anchor.edges: root.edge
      anchor.gravity: root.edge
      anchor.adjustment: PopupAdjustment.Slide
      anchor.margins.top: Style.spacing.xs
      implicitWidth: content.implicitWidth
      implicitHeight: content.implicitHeight

      Rectangle {
        id: content
        anchors.fill: parent
        implicitWidth: label.implicitWidth + Style.spacing.lg * 2
        implicitHeight: label.implicitHeight + Style.spacing.sm * 2
        color: Theme.tooltip.background
        border.color: Theme.tooltip.border
        border.width: 1

        Text {
          id: label
          anchors.centerIn: parent
          text: root.text
          textFormat: Text.PlainText
          color: Theme.tooltip.text
          font.family: Style.font.family
          font.pixelSize: Style.font.small
          renderType: Text.NativeRendering
        }
      }
    }
  }
}
