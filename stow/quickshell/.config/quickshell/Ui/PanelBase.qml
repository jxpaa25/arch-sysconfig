import QtQuick
import qs.Commons

// The inside of a bar panel: a title and a scrolling column. Up and Down walk the rows,
// Enter activates, Left and Right adjust a slider, Delete does a row's second action.
Item {
  id: root

  property string title: ""
  property string subtitle: ""
  property int panelWidth: Style.space(380)
  property Item cursor: null
  default property alias content: column.data

  readonly property int padding: Style.spacing.panel

  implicitWidth: panelWidth
  implicitHeight: padding * 2 + header.implicitHeight + Style.spacing.lg + column.implicitHeight

  function rows(item, out) {
    var list = out || []
    var children = (item || column).children
    for (var i = 0; i < children.length; i++) {
      var child = children[i]
      if (!child.visible) continue
      if (child.isPanelRow === true) list.push(child)
      else rows(child, list)
    }
    return list
  }

  function move(delta) {
    var list = rows()
    if (!list.length) return
    var at = list.indexOf(cursor)
    if (at < 0) at = delta > 0 ? -1 : 0
    cursor = list[(at + delta + list.length) % list.length]
    var y = cursor.mapToItem(column, 0, 0).y
    if (y < flick.contentY) flick.contentY = y
    else if (y + cursor.height > flick.contentY + flick.height) flick.contentY = y + cursor.height - flick.height
  }

  // PanelHost hands over the keys it doesn't handle itself. Returns whether this used it.
  function handleKey(event) {
    switch (event.key) {
    case Qt.Key_Up:
    case Qt.Key_K:
      move(-1)
      return true
    case Qt.Key_Down:
    case Qt.Key_J:
      move(1)
      return true
    case Qt.Key_Left:
    case Qt.Key_H:
      if (cursor) cursor.adjust(-1)
      return true
    case Qt.Key_Right:
    case Qt.Key_L:
      if (cursor) cursor.adjust(1)
      return true
    case Qt.Key_Delete:
      if (cursor) cursor.secondary()
      return true
    case Qt.Key_Return:
    case Qt.Key_Enter:
    case Qt.Key_Space:
      if (cursor) cursor.activate()
      return true
    }
    return extraKey(event)
  }

  // For a panel with keys of its own.
  function extraKey(event) {
    return false
  }

  Column {
    id: header

    anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.padding }
    spacing: Style.spacing.xs

    Text {
      width: parent.width
      text: root.title
      textFormat: Text.PlainText
      color: Theme.popup.text
      opacity: 0.6
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.capitalization: Font.AllLowercase
      elide: Text.ElideRight
    }

    Text {
      width: parent.width
      visible: text !== ""
      text: root.subtitle
      textFormat: Text.PlainText
      color: Theme.popup.text
      opacity: 0.4
      font.family: Style.font.family
      font.pixelSize: Style.font.small
      font.capitalization: Font.AllLowercase
      elide: Text.ElideRight
    }
  }

  Flickable {
    id: flick

    anchors { left: parent.left; right: parent.right; top: header.bottom; bottom: parent.bottom }
    anchors { leftMargin: root.padding; rightMargin: root.padding; topMargin: Style.spacing.lg; bottomMargin: root.padding }
    contentHeight: column.implicitHeight
    boundsBehavior: Flickable.StopAtBounds
    clip: true

    Column {
      id: column
      width: flick.width
      spacing: Style.spacing.xs
    }
  }
}
