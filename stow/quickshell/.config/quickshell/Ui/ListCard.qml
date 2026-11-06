import QtQuick
import qs.Commons

// A searchable list in a card, driven by the keyboard. Rows are plain objects:
//   { icon, image, label, detail, hint, more, checked }
// The owner filters: it watches `filter` and hands back the rows to show.
FocusScope {
  id: root

  property var rows: []
  property string placeholder: "Search…"
  property int cardWidth: Style.space(500)
  property int maxRows: 12
  property bool canGoBack: false
  readonly property alias filter: input.text

  property int selected: 0
  readonly property int rowHeight: Style.space(38)
  readonly property int detailRowHeight: Style.space(50)
  readonly property int padding: Style.spacing.panel
  readonly property int headerHeight: Math.max(Style.space(34), Style.font.title + Style.spacing.md * 2)
  readonly property int listHeight: Math.min(list.contentHeight, maxRows * rowHeight)

  signal activated(var row)
  signal back
  signal cancelled

  width: cardWidth
  height: padding * 2 + headerHeight + Style.spacing.sm + (rows.length ? listHeight : Style.space(80))

  function reset() {
    input.text = ""
    selected = 0
    list.positionViewAtBeginning()
    input.forceActiveFocus()
  }

  function move(delta) {
    if (!rows.length) return
    selected = (selected + delta + rows.length) % rows.length
    list.positionViewAtIndex(selected, ListView.Contain)
  }

  onRowsChanged: {
    selected = 0
    list.positionViewAtBeginning()
  }

  // The card swallows clicks, so only clicks outside it dismiss the overlay.
  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.AllButtons
  }

  Rectangle {
    anchors.fill: parent
    color: Theme.menu.background
    border.color: Theme.menu.border
    border.width: Style.border
    radius: Style.radius
  }

  TextInput {
    id: input
    anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.padding }
    height: root.headerHeight
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.menu.text
    selectionColor: Theme.withAlpha(Theme.menu.text, 0.35)
    selectedTextColor: Theme.menu.text
    font.family: Style.font.family
    font.pixelSize: Style.font.heading
    clip: true
    focus: true

    Keys.onPressed: function(event) {
      var ctrl = event.modifiers & Qt.ControlModifier
      switch (event.key) {
      case Qt.Key_Escape:
        if (text) text = ""
        else root.cancelled()
        break
      case Qt.Key_Backspace:
      case Qt.Key_Left:
        if (text || !root.canGoBack) return
        root.back()
        break
      case Qt.Key_Up:
        root.move(-1)
        break
      case Qt.Key_Down:
        root.move(1)
        break
      case Qt.Key_PageUp:
        root.move(-6)
        break
      case Qt.Key_PageDown:
        root.move(6)
        break
      case Qt.Key_K:
        if (!ctrl) return
        root.move(-1)
        break
      case Qt.Key_J:
        if (!ctrl) return
        root.move(1)
        break
      case Qt.Key_Right:
        if (text || !root.rows.length || !root.rows[root.selected].more) return
        root.activated(root.rows[root.selected])
        break
      case Qt.Key_Return:
      case Qt.Key_Enter:
        if (root.rows.length) root.activated(root.rows[root.selected])
        break
      default:
        return
      }
      event.accepted = true
    }

    Text {
      anchors.fill: parent
      verticalAlignment: Text.AlignVCenter
      visible: !input.text
      text: root.placeholder
      color: Theme.menu.text
      opacity: 0.58
      font: input.font
      elide: Text.ElideRight
    }
  }

  ListView {
    id: list
    anchors { left: parent.left; right: parent.right; top: input.bottom; margins: root.padding; topMargin: Style.spacing.sm }
    height: root.listHeight
    clip: true
    model: root.rows
    boundsBehavior: Flickable.StopAtBounds
    reuseItems: true

    delegate: Item {
      id: row

      required property int index
      required property var modelData

      readonly property bool current: index === root.selected
      readonly property color textColor: current ? Theme.menu.selectedText : Theme.menu.text

      width: ListView.view.width
      height: modelData.detail ? root.detailRowHeight : root.rowHeight

      Rectangle {
        anchors.fill: parent
        color: row.current ? Theme.menu.selectedBackground : "transparent"
        border.color: row.current ? Theme.menu.selectedBorder : "transparent"
        border.width: 1
        radius: Style.radius
      }

      Text {
        id: iconText
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        width: row.modelData.icon || row.modelData.image ? Style.space(44) : Style.space(12)
        horizontalAlignment: Text.AlignHCenter
        text: row.modelData.icon || ""
        textFormat: Text.PlainText
        color: row.textColor
        font.family: Style.font.family
        font.pixelSize: Style.font.iconLarge
      }

      Image {
        anchors.centerIn: iconText
        width: Style.font.iconLarge + Style.space(2)
        height: width
        visible: !!row.modelData.image
        source: row.modelData.image || ""
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        fillMode: Image.PreserveAspectFit
        asynchronous: true
      }

      Column {
        anchors { left: iconText.right; right: trail.left; verticalCenter: parent.verticalCenter; rightMargin: Style.spacing.md }
        spacing: Style.spacing.xs

        Text {
          width: parent.width
          text: row.modelData.label
          textFormat: Text.PlainText
          color: row.textColor
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          font.weight: Font.Medium
          elide: Text.ElideRight
        }

        Text {
          width: parent.width
          visible: !!row.modelData.detail
          text: row.modelData.detail || ""
          textFormat: Text.PlainText
          color: Theme.menu.text
          opacity: 0.52
          font.family: Style.font.family
          font.pixelSize: Style.font.small
          elide: Text.ElideRight
        }
      }

      Row {
        id: trail
        anchors { right: parent.right; verticalCenter: parent.verticalCenter; rightMargin: Style.spacing.lg }
        spacing: Style.spacing.md

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !!row.modelData.hint
          text: row.modelData.hint || ""
          textFormat: Text.PlainText
          color: Theme.menu.text
          opacity: 0.52
          font.family: Style.font.family
          font.pixelSize: Style.font.small
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: !!row.modelData.checked || !!row.modelData.more
          text: row.modelData.checked ? "✓" : "›"
          color: row.textColor
          opacity: row.modelData.checked ? 1 : 0.36
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
        }
      }

      MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        // Only a pointer that actually moves takes the cursor, so a list scrolling under a
        // resting pointer doesn't steal it.
        onPositionChanged: root.selected = row.index
        onClicked: root.activated(row.modelData)
      }
    }
  }

  Text {
    anchors { left: parent.left; right: parent.right; top: input.bottom; topMargin: Style.space(24) }
    visible: !root.rows.length
    horizontalAlignment: Text.AlignHCenter
    text: "Nothing found"
    color: Theme.menu.text
    opacity: 0.7
    font.family: Style.font.family
    font.pixelSize: Style.font.title
  }
}
