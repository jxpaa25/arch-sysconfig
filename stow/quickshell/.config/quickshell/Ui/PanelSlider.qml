import QtQuick
import qs.Commons

// A labelled slider from 0 to 1. Click its icon for the second action, such as mute.
Item {
  id: root

  readonly property bool isPanelRow: true
  property string icon: ""
  property string label: ""
  property real value: 0
  property real step: 0.05
  property bool dimmed: false

  readonly property var panel: {
    for (var item = parent; item; item = item.parent) {
      if (item.cursor !== undefined && item.handleKey !== undefined) return item
    }
    return null
  }
  readonly property bool hasCursor: !!panel && panel.cursor === root

  signal moved(real value)
  signal iconClicked

  function activate() { iconClicked() }
  function secondary() {}
  function adjust(delta) { moved(Math.max(0, Math.min(1, value + delta * step))) }

  width: parent ? parent.width : 0
  implicitHeight: Style.space(label ? 46 : 32)

  Rectangle {
    anchors.fill: parent
    color: root.hasCursor ? Theme.control.selectedFill : "transparent"
  }

  Text {
    id: iconText
    anchors { left: parent.left; bottom: parent.bottom; bottomMargin: Style.space(5) }
    width: Style.space(30)
    horizontalAlignment: Text.AlignHCenter
    text: root.icon
    textFormat: Text.PlainText
    color: Theme.popup.text
    font.family: Style.font.family
    font.pixelSize: Style.font.icon

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.iconClicked()
    }
  }

  Text {
    anchors { left: iconText.right; right: value.left; top: parent.top; topMargin: Style.space(4); rightMargin: Style.spacing.md }
    visible: root.label !== ""
    text: root.label
    textFormat: Text.PlainText
    color: Theme.popup.text
    opacity: 0.8
    font.family: Style.font.family
    font.pixelSize: Style.font.small
    elide: Text.ElideRight
  }

  Text {
    id: value
    anchors { right: parent.right; rightMargin: Style.spacing.lg; verticalCenter: track.verticalCenter }
    width: Style.space(36)
    horizontalAlignment: Text.AlignRight
    text: Math.round(root.value * 100) + "%"
    color: Theme.popup.text
    opacity: 0.7
    font.family: Style.font.family
    font.pixelSize: Style.font.small
  }

  Item {
    id: track

    anchors { left: iconText.right; right: value.left; bottom: parent.bottom; rightMargin: Style.spacing.md }
    height: Style.space(20)
    anchors.bottomMargin: Style.space(4)

    // A hairline with a tick at the value.
    Rectangle {
      anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
      height: 1
      color: Theme.withAlpha(Theme.popup.text, 0.3)
    }

    Rectangle {
      anchors { left: parent.left; verticalCenter: parent.verticalCenter }
      width: parent.width * Math.max(0, Math.min(1, root.value))
      height: 1
      color: Theme.popup.text
      opacity: root.dimmed ? 0.4 : 1
    }

    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      x: (parent.width - width) * Math.max(0, Math.min(1, root.value))
      width: Style.space(3)
      height: Style.space(11)
      color: Theme.popup.text
      opacity: root.dimmed ? 0.4 : 1
    }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      preventStealing: true
      function apply(x) { root.moved(Math.max(0, Math.min(1, x / width))) }
      onPressed: function(event) { apply(event.x) }
      onPositionChanged: function(event) { if (pressed) apply(event.x) }
      onWheel: function(event) { root.adjust(event.angleDelta.y > 0 ? 1 : -1) }
    }
  }
}
