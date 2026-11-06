import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.Commons

// The on-screen display for volume, microphone mute and brightness. It lets clicks through.
Scope {
  id: root

  property string glyph: ""
  property string message: ""
  property real progress: -1
  property bool shown: false
  // Pipewire reports everything once as it connects, which isn't a change worth showing.
  property bool armed: false

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property var source: Pipewire.defaultAudioSource

  function show(glyph, progress, message) {
    root.glyph = glyph
    root.progress = progress
    root.message = message || ""
    shown = true
    hide.restart()
  }

  function showVolume() {
    if (!armed || !sink || !sink.audio) return
    var volume = sink.audio.volume
    var muted = sink.audio.muted
    var code = 0xF057E
    if (muted || volume <= 0) code = 0xF0581
    else if (volume < 0.34) code = 0xF057F
    else if (volume < 0.67) code = 0xF0580
    show(String.fromCodePoint(code), muted ? 0 : volume, "")
  }

  function showMic() {
    if (!armed || !source || !source.audio) return
    var muted = source.audio.muted
    show(String.fromCodePoint(muted ? 0xF036D : 0xF036C), -1, muted ? "Microphone off" : "Microphone on")
  }

  PwObjectTracker {
    objects: [root.sink, root.source].filter(Boolean)
  }

  Connections {
    target: root.sink ? root.sink.audio : null
    function onVolumeChanged() { root.showVolume() }
    function onMutedChanged() { root.showVolume() }
  }

  Connections {
    target: root.source ? root.source.audio : null
    function onMutedChanged() { root.showMic() }
  }

  Timer {
    interval: 2000
    running: true
    onTriggered: root.armed = true
  }

  Timer {
    id: hide
    interval: 1500
    onTriggered: root.shown = false
  }

  PanelWindow {
    screen: Panels.screenByName(Panels.focusedScreenName())
    visible: root.shown
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    anchors.bottom: true
    margins.bottom: Style.space(60)
    implicitWidth: card.width
    implicitHeight: card.height
    mask: Region {}
    WlrLayershell.namespace: "desk-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Rectangle {
      id: card

      width: contents.implicitWidth + Style.spacing.panel * 2
      height: contents.implicitHeight + Style.spacing.panel * 2
      color: Theme.popup.background
      border.color: Theme.popup.border
      border.width: Style.border
      radius: Style.radius

      Row {
        id: contents
        anchors.centerIn: parent
        spacing: Style.space(12)

        Text {
          anchors.verticalCenter: parent.verticalCenter
          text: root.glyph
          color: Theme.popup.text
          font.family: Style.font.family
          font.pixelSize: Style.font.display
        }

        Rectangle {
          anchors.verticalCenter: parent.verticalCenter
          visible: root.progress >= 0
          width: Style.space(180)
          height: Style.space(6)
          color: Theme.withAlpha(Theme.popup.text, 0.15)

          Rectangle {
            width: parent.width * Math.min(1, Math.max(0, root.progress))
            height: parent.height
            color: Theme.popup.text

            Behavior on width {
              NumberAnimation { duration: Style.fast; easing.type: Easing.OutCubic }
            }
          }
        }

        Text {
          anchors.verticalCenter: parent.verticalCenter
          visible: text !== ""
          width: root.progress >= 0 ? Style.space(36) : implicitWidth
          horizontalAlignment: Text.AlignRight
          text: root.progress >= 0 ? Math.round(root.progress * 100) + "%" : root.message
          textFormat: Text.PlainText
          color: Theme.popup.text
          font.family: Style.font.family
          font.bold: true
          font.pixelSize: Style.font.title
        }
      }
    }
  }

  IpcHandler {
    target: "osd"

    function brightness(percent: int): void {
      root.show(String.fromCodePoint(0xF00E0), percent / 100, "")
    }
    function keyboardBacklight(percent: int): void {
      root.show(String.fromCodePoint(0xF0B8C), percent / 100, "")
    }
    function message(text: string): void {
      root.show(String.fromCodePoint(0xF02D6), -1, text)
    }
  }
}
