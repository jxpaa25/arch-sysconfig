import QtQuick
import qs.Commons

// One row in a panel. Set `toggled` to make it a switch. PanelBase drives it from the keyboard.
Item {
  id: root

  readonly property bool isPanelRow: true
  property string icon: ""
  property string label: ""
  property string detail: ""
  property string trailing: ""
  property bool selected: false
  // -1 means this isn't a switch.
  property int toggled: -1
  property bool interactive: true

  readonly property var panel: {
    for (var item = parent; item; item = item.parent) {
      if (item.cursor !== undefined && item.handleKey !== undefined) return item
    }
    return null
  }
  readonly property bool hasCursor: !!panel && panel.cursor === root
  // The row with the keyboard cursor is a solid block, like the selection everywhere else.
  readonly property color ink: hasCursor ? Theme.popup.background : Theme.popup.text

  signal clicked
  signal secondaryAction
  signal adjusted(int delta)

  function activate() { if (interactive) clicked() }
  function secondary() { secondaryAction() }
  function adjust(delta) { adjusted(delta) }

  width: parent ? parent.width : 0
  implicitHeight: detail ? Style.space(44) : Style.spacing.row + Style.space(4)

  Rectangle {
    anchors.fill: parent
    color: root.hasCursor ? Theme.popup.text
      : (mouse.containsMouse && root.interactive ? Theme.control.hoverFill
        : (root.selected ? Theme.control.selectedFill : "transparent"))
  }

  Text {
    id: iconText
    anchors { left: parent.left; verticalCenter: parent.verticalCenter }
    width: Style.space(30)
    horizontalAlignment: Text.AlignHCenter
    text: root.icon
    textFormat: Text.PlainText
    color: root.ink
    font.family: Style.font.family
    font.pixelSize: Style.font.icon
  }

  Column {
    anchors { left: iconText.right; right: trail.left; verticalCenter: parent.verticalCenter; rightMargin: Style.spacing.md }
    spacing: Style.space(2)

    Text {
      width: parent.width
      text: root.label
      textFormat: Text.PlainText
      color: root.ink
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: root.detail
      textFormat: Text.PlainText
      color: root.ink
      opacity: 0.55
      font.family: Style.font.family
      font.pixelSize: Style.font.small
      elide: Text.ElideRight
    }
  }

  Row {
    id: trail
    anchors { right: parent.right; rightMargin: Style.spacing.lg; verticalCenter: parent.verticalCenter }
    spacing: Style.spacing.md

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: text !== ""
      text: root.trailing
      textFormat: Text.PlainText
      color: root.ink
      opacity: 0.6
      font.family: Style.font.family
      font.pixelSize: Style.font.small
    }

    // The switch, in words.
    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: root.toggled >= 0
      text: root.toggled === 1 ? "on" : "off"
      color: root.ink
      opacity: root.toggled === 1 ? 1 : 0.45
      font.family: Style.font.family
      font.pixelSize: Style.font.small
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    enabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(event) {
      if (event.button === Qt.RightButton) root.secondary()
      else root.activate()
    }
  }
}
