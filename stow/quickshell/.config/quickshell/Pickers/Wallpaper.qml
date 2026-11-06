import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Choose a background from ~/Pictures/Wallpapers, or the theme's plain colour.
// Left and right to move, Enter to apply, Escape to leave.
Scope {
  id: root

  property bool opened: false
  // "" stands for the plain colour, and always comes first.
  property var images: [""]
  readonly property string folder: Quickshell.env("HOME") + "/Pictures/Wallpapers"

  function open() {
    finder.running = true
    opened = true
  }

  function apply(path) {
    Saved.wallpaper = path
    opened = false
  }

  Process {
    id: finder
    command: ["find", "-L", root.folder, "-type", "f", "(", "-iname", "*.jpg", "-o", "-iname", "*.jpeg", "-o", "-iname", "*.png", "-o", "-iname", "*.webp", ")"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.images = [""].concat(text.split("\n").filter(Boolean).sort())
        var at = root.images.indexOf(Saved.wallpaper)
        list.currentIndex = at < 0 ? 0 : at
        list.positionViewAtIndex(list.currentIndex, ListView.Center)
      }
    }
  }

  Overlay {
    id: overlay

    shown: root.opened
    scrim: Theme.menu.scrim
    WlrLayershell.namespace: "desk-wallpaper"
    onDismissed: root.opened = false
    onShownChanged: if (shown) list.forceActiveFocus()

    ListView {
      id: list

      readonly property int cardWidth: Style.space(420)
      readonly property int cardHeight: Math.round(cardWidth * 9 / 16)

      anchors.centerIn: parent
      width: parent.width
      height: cardHeight + Style.space(36)
      orientation: ListView.Horizontal
      spacing: Style.spacing.xl
      model: root.images
      focus: true
      keyNavigationWraps: true
      highlightMoveDuration: Style.normal
      highlightRangeMode: ListView.StrictlyEnforceRange
      preferredHighlightBegin: (width - cardWidth) / 2
      preferredHighlightEnd: (width + cardWidth) / 2

      Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Return:
        case Qt.Key_Enter:
          root.apply(root.images[currentIndex])
          break
        case Qt.Key_Escape:
          root.opened = false
          break
        case Qt.Key_H:
          decrementCurrentIndex()
          break
        case Qt.Key_L:
          incrementCurrentIndex()
          break
        default:
          return
        }
        event.accepted = true
      }

      delegate: Column {
        id: entry

        required property int index
        required property string modelData

        readonly property bool current: ListView.isCurrentItem

        spacing: Style.spacing.md
        opacity: current ? 1 : 0.55

        Rectangle {
          width: list.cardWidth
          height: list.cardHeight
          color: Theme.background
          border.color: entry.current ? Theme.menu.border : Theme.withAlpha(Theme.menu.text, 0.28)
          border.width: Style.border

          Image {
            anchors { fill: parent; margins: Style.border }
            visible: entry.modelData !== ""
            source: entry.modelData ? "file://" + entry.modelData : ""
            sourceSize.width: list.cardWidth * 2
            sourceSize.height: list.cardHeight * 2
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            clip: true
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              if (entry.current) root.apply(entry.modelData)
              else list.currentIndex = entry.index
            }
          }
        }

        Text {
          width: list.cardWidth
          horizontalAlignment: Text.AlignHCenter
          text: entry.modelData ? entry.modelData.split("/").pop() : "Plain colour"
          textFormat: Text.PlainText
          color: Theme.menu.text
          elide: Text.ElideMiddle
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }
      }
    }
  }

  IpcHandler {
    target: "wallpaper"

    function toggle(): void {
      if (root.opened) root.opened = false
      else root.open()
    }
  }
}
