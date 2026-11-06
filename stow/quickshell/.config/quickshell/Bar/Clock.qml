import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// Date and time. Left click opens the calendar, right click walks the formats in Settings.
PanelButton {
  id: root

  panelId: "clock"
  bold: true
  margin: Style.spaceReal(8.75)
  fontSize: Style.font.body

  readonly property string format: {
    var saved = Saved.clockFormat
    return Settings.clockFormats.indexOf(saved) !== -1 ? saved : Settings.clockFormats[0]
  }

  // Qt has no ISO week token, so "ww" gets replaced before formatting.
  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    var day = d.getUTCDay() || 7
    d.setUTCDate(d.getUTCDate() + 4 - day)
    var start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    var week = Math.ceil(((d - start) / 86400000 + 1) / 7)
    return (week < 10 ? "0" : "") + week
  }

  text: Qt.formatDateTime(clock.date, format.replace(/ww/g, isoWeek(clock.date)))

  onClicked: function(button) {
    if (button !== Qt.RightButton) return
    var formats = Settings.clockFormats
    Saved.clockFormat = formats[(formats.indexOf(format) + 1) % formats.length]
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }
}
