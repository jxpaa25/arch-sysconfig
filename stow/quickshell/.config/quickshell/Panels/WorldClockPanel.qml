import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// The time in each city from Settings.worldClocks, and how far it is from here.
PanelBase {
  id: root

  title: "World clock"

  property var rows: []

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
    onDateChanged: root.refresh()
  }

  function refresh() {
    if (!query.running) query.running = true
  }

  Component.onCompleted: refresh()

  function offsetLabel(zoneOffset, localOffset) {
    var hours = (zoneOffset - localOffset) / 3600
    if (hours === 0) return "Same time"
    var whole = Math.abs(hours)
    return (hours > 0 ? "+" : "−") + whole + "h"
  }

  Process {
    id: query
    // QML can't format a time in another zone, but date can. One line per city.
    command: ["bash", "-c", 'date +%z; for zone in "$@"; do TZ=$zone date "+%H:%M|%a %-d %b|%z"; done', "--"]
      .concat(Settings.worldClocks.map(function(city) { return city.zone }))
    stdout: StdioCollector {
      onStreamFinished: {
        function seconds(z) {
          var sign = z.charAt(0) === "-" ? -1 : 1
          return sign * (parseInt(z.substr(1, 2), 10) * 3600 + parseInt(z.substr(3, 2), 10) * 60)
        }
        var lines = text.trim().split("\n")
        var here = seconds(lines[0])
        root.rows = lines.slice(1).map(function(line, i) {
          var parts = line.split("|")
          return {
            name: Settings.worldClocks[i].name,
            time: parts[0],
            day: parts[1],
            offset: root.offsetLabel(seconds(parts[2]), here)
          }
        })
      }
    }
  }

  Repeater {
    model: root.rows

    PanelRow {
      required property var modelData
      interactive: false
      icon: String.fromCodePoint(0xF01E7)
      label: modelData.name
      detail: modelData.day + "  " + modelData.offset
      trailing: modelData.time
    }
  }
}
