import QtQuick
import qs.Commons

// One clickable thing on the bar: a label or an icon, with an optional tooltip.
Item {
  id: root

  property string text: ""
  // A dim word in front of the text, as in "cpu 12%".
  property string note: ""
  // Solid block behind the text, for the thing that's selected.
  property bool inverted: false
  property string tooltip: ""
  property real fontSize: Style.font.body
  property bool bold: false
  property bool active: false
  property real labelOpacity: 1
  property real margin: Style.spaceReal(8.5)
  property real fixedWidth: -1

  readonly property bool hovered: mouse.containsMouse

  signal clicked(int button)
  signal wheeled(int delta)

  implicitWidth: fixedWidth > 0 ? fixedWidth : content.implicitWidth + margin * 2
  implicitHeight: Style.bar.size

  Rectangle {
    anchors { fill: parent; bottomMargin: 1 }
    visible: root.inverted
    color: Theme.bar.text
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(5)
    scale: mouse.pressed ? 0.88 : 1

    Behavior on scale {
      NumberAnimation { duration: Style.fast; easing.type: Easing.OutCubic }
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.note !== ""
      text: root.note
      textFormat: Text.PlainText
      color: Theme.bar.text
      opacity: 0.45
      font.family: Style.font.family
      font.pixelSize: root.fontSize
      renderType: Text.NativeRendering
    }

    Text {
      id: label
      anchors.verticalCenter: parent.verticalCenter
      text: root.text
      textFormat: Text.PlainText
      color: root.inverted ? Theme.bar.background : (root.active ? Theme.bar.active : Theme.bar.text)
      opacity: root.labelOpacity
      font.family: Style.font.family
      font.pixelSize: root.fontSize
      font.bold: root.bold
      renderType: Text.NativeRendering
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    onClicked: function(event) { root.clicked(event.button) }
    onWheel: function(event) { root.wheeled(event.angleDelta.y) }
  }

  Tooltip {
    target: root
    text: root.tooltip
    shown: root.hovered
  }
}
