import QtQuick
import qs.Commons
import qs.Ui

// Quiet toggles. Each one stays hidden unless it's on or the pointer is over the bar,
// but always keeps its place, so nothing on the bar shifts when they appear.
Row {
  id: root

  property bool barHovered: false

  component Indicator: BarButton {
    id: indicator
    property bool on: false
    property string glyph: ""
    text: glyph
    fixedWidth: Style.bar.statusSlot
    fontSize: Style.font.caption
    active: on
    opacity: on || root.barHovered ? (on ? 1 : 0.5) : 0

    Behavior on opacity {
      NumberAnimation { duration: Style.fast }
    }
  }

  Indicator {
    on: Status.recording
    glyph: String.fromCodePoint(0xF044B)
    tooltip: on ? "Stop recording" : "Record the screen"
    onClicked: Run.sh("screen-record")
  }

  Indicator {
    on: Saved.doNotDisturb
    glyph: String.fromCodePoint(0xF009B)
    tooltip: on ? "Allow notifications" : "Silence notifications"
    onClicked: Saved.doNotDisturb = !Saved.doNotDisturb
  }

  Indicator {
    on: Saved.nightLight
    glyph: String.fromCodePoint(0xF050E)
    tooltip: on ? "Day light" : "Night light"
    onClicked: Status.toggleNightLight()
  }

  Indicator {
    on: Saved.stayAwake
    glyph: String.fromCodePoint(0xF0176)
    tooltip: on ? "Allow idle lock and screensaver" : "Stay awake"
    onClicked: Saved.stayAwake = !Saved.stayAwake
  }
}
