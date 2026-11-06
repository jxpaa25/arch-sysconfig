import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.Commons
import qs.Ui

// System tray, kept behind a chevron. Hovering opens the drawer, and it stays open while
// one of its menus is showing. Left click activates an item, right click opens its menu.
Row {
  id: root

  readonly property var items: SystemTray.items.values
  readonly property bool open: hover.hovered || menu.visible

  visible: items.length > 0
  width: visible ? implicitWidth : 0
  height: Style.bar.size

  HoverHandler { id: hover }

  QsMenuAnchor {
    id: menu
    anchor.window: root.QsWindow.window
    anchor.edges: Edges.Bottom
    anchor.gravity: Edges.Bottom
  }

  Item {
    id: drawer
    height: parent.height
    width: root.open ? list.implicitWidth : 0
    clip: true

    Behavior on width {
      NumberAnimation { duration: Style.normal; easing.type: Easing.OutCubic }
    }

    Row {
      id: list
      anchors.right: parent.right
      height: parent.height

      Repeater {
        model: root.items

        Item {
          id: entry

          required property var modelData

          width: Style.bar.iconSlot
          height: Style.bar.size

          Image {
            anchors.centerIn: parent
            width: Style.font.iconLarge
            height: width
            sourceSize.width: width * 2
            sourceSize.height: height * 2
            source: entry.modelData.icon
            fillMode: Image.PreserveAspectFit
            smooth: true
          }

          MouseArea {
            id: entryMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            onClicked: function(event) {
              var item = entry.modelData
              if (event.button === Qt.MiddleButton) {
                item.secondaryActivate()
              } else if (event.button === Qt.RightButton || item.onlyMenu) {
                if (!item.hasMenu) return
                var point = entry.mapToItem(null, 0, entry.height)
                menu.menu = item.menu
                menu.anchor.rect.x = point.x
                menu.anchor.rect.y = point.y
                menu.anchor.rect.width = entry.width
                menu.anchor.rect.height = 1
                menu.open()
              } else {
                item.activate()
              }
            }

            onWheel: function(event) {
              entry.modelData.scroll(event.angleDelta.y, false)
            }
          }

          Tooltip {
            target: entry
            text: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
            shown: entryMouse.containsMouse
          }
        }
      }
    }
  }

  BarButton {
    text: root.open ? String.fromCodePoint(0xF0142) : String.fromCodePoint(0xF0141)
    tooltip: root.items.length + (root.items.length === 1 ? " tray item" : " tray items")
    fixedWidth: Style.bar.statusSlot
    fontSize: Style.font.caption
    labelOpacity: 0.6
  }
}
