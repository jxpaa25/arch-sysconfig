import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons

// A clock that wanders a little, so nothing stays burned in one place. Any key or pointer
// movement brings the desktop back.
PanelWindow {
  id: root

  property bool shown: false
  signal dismissed

  visible: shown
  color: Theme.background
  exclusionMode: ExclusionMode.Ignore
  anchors { top: true; bottom: true; left: true; right: true }
  WlrLayershell.namespace: "desk-screensaver"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

  // The window opening under a still pointer counts as movement, so ignore the first moment.
  property bool settled: false
  onShownChanged: {
    settled = false
    if (shown) {
      settle.restart()
      keys.forceActiveFocus()
    }
  }

  Timer { id: settle; interval: 800; onTriggered: root.settled = true }

  function wander() {
    clock.x = Math.random() * Math.max(0, root.width - clock.width)
    clock.y = Math.random() * Math.max(0, root.height - clock.height)
  }

  Timer {
    interval: 30000
    repeat: true
    running: root.shown
    triggeredOnStart: true
    onTriggered: root.wander()
  }

  SystemClock {
    id: time
    precision: SystemClock.Minutes
  }

  Column {
    id: clock
    spacing: Style.space(4)

    Behavior on x { NumberAnimation { duration: 2000; easing.type: Easing.InOutSine } }
    Behavior on y { NumberAnimation { duration: 2000; easing.type: Easing.InOutSine } }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(time.date, "HH:mm")
      color: Theme.foreground
      opacity: 0.7
      font.family: Style.font.family
      font.pixelSize: Style.space(96)
    }

    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: Qt.formatDateTime(time.date, "dddd d MMMM")
      color: Theme.foreground
      opacity: 0.4
      font.family: Style.font.family
      font.pixelSize: Style.font.title
    }
  }

  Item {
    id: keys
    anchors.fill: parent
    focus: true
    Keys.onPressed: function(event) {
      event.accepted = true
      if (root.settled) root.dismissed()
    }
  }

  MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.BlankCursor
    acceptedButtons: Qt.AllButtons
    onPositionChanged: if (root.settled) root.dismissed()
    onPressed: if (root.settled) root.dismissed()
  }
}
