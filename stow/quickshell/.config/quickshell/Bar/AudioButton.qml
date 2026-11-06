import QtQuick
import Quickshell.Services.Pipewire
import qs.Commons

// Volume. Left click opens the panel, right click mutes, scrolling changes the volume.
PanelButton {
  id: root

  panelId: "audio"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot

  readonly property var sink: Pipewire.defaultAudioSink
  readonly property bool ready: sink && sink.ready && sink.audio
  readonly property real volume: ready ? sink.audio.volume : 0
  readonly property bool muted: ready ? sink.audio.muted : false

  text: {
    if (!ready || muted || volume <= 0) return String.fromCodePoint(0xF0581)
    if (volume < 0.34) return String.fromCodePoint(0xF057F)
    if (volume < 0.67) return String.fromCodePoint(0xF0580)
    return String.fromCodePoint(0xF057E)
  }
  tooltip: ready ? (muted ? "Muted" : Math.round(volume * 100) + "%") : "No audio output"

  PwObjectTracker { objects: root.sink ? [root.sink] : [] }

  onClicked: function(button) {
    if (button === Qt.RightButton && root.ready) root.sink.audio.muted = !root.muted
  }

  onWheeled: function(delta) {
    if (root.ready) root.sink.audio.volume = Math.max(0, Math.min(1, root.volume + (delta > 0 ? 0.05 : -0.05)))
  }
}
