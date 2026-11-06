import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// A month at a time, with ISO week numbers. Left and Right change month, T returns to today.
PanelBase {
  id: root

  panelWidth: Style.space(360)

  SystemClock {
    id: clock
    precision: SystemClock.Hours
  }

  readonly property date today: clock.date
  property int year: today.getFullYear()
  property int month: today.getMonth()

  title: Qt.locale().standaloneMonthName(month, Locale.LongFormat) + " " + year
  subtitle: Qt.formatDate(today, "dddd d MMMM")

  function step(delta) {
    var next = new Date(year, month + delta, 1)
    year = next.getFullYear()
    month = next.getMonth()
  }

  function goToToday() {
    year = today.getFullYear()
    month = today.getMonth()
  }

  function isoWeek(date) {
    var d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
    d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7))
    var start = new Date(Date.UTC(d.getUTCFullYear(), 0, 1))
    return Math.ceil(((d - start) / 86400000 + 1) / 7)
  }

  // Six weeks starting from the Monday on or before the 1st.
  readonly property var days: {
    var first = new Date(year, month, 1)
    var back = (first.getDay() + 6) % 7
    var out = []
    for (var i = 0; i < 42; i++) out.push(new Date(year, month, 1 - back + i))
    return out
  }

  function extraKey(event) {
    if (event.key === Qt.Key_T) {
      goToToday()
      return true
    }
    return false
  }

  // PanelBase turns these into adjust() on the row with the cursor, and this panel has one.
  Component.onCompleted: cursor = navigator

  Item {
    id: navigator

    readonly property bool isPanelRow: true
    function activate() { root.goToToday() }
    function secondary() {}
    function adjust(delta) { root.step(delta) }
    width: parent ? parent.width : 0
    implicitHeight: Style.space(28)

    Row {
      anchors.centerIn: parent
      spacing: Style.space(12)

      Repeater {
        model: [
          { glyph: "‹", act: function() { root.step(-1) } },
          { glyph: "Today", act: function() { root.goToToday() } },
          { glyph: "›", act: function() { root.step(1) } }
        ]

        Text {
          required property var modelData
          text: modelData.glyph
          color: Theme.popup.text
          opacity: navMouse.containsMouse ? 1 : 0.6
          font.family: Style.font.family
          font.pixelSize: Style.font.title

          MouseArea {
            id: navMouse
            anchors.fill: parent
            anchors.margins: -Style.space(4)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.modelData.act()
          }
        }
      }
    }
  }

  Grid {
    id: grid

    readonly property real cell: width / 8

    width: parent ? parent.width : 0
    columns: 8
    topPadding: Style.spacing.md

    Text {
      width: grid.cell
      height: Style.space(26)
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      text: "W"
      color: Theme.popup.text
      opacity: 0.35
      font.family: Style.font.family
      font.pixelSize: Style.font.small
    }

    Repeater {
      model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

      Text {
        required property string modelData
        width: grid.cell
        height: Style.space(26)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: modelData
        color: Theme.popup.text
        opacity: 0.55
        font.family: Style.font.family
        font.pixelSize: Style.font.small
      }
    }
  }

  Repeater {
    model: 6

    Row {
      id: week

      required property int index

      width: parent ? parent.width : 0

      Text {
        width: parent.width / 8
        height: Style.space(30)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.isoWeek(root.days[week.index * 7])
        color: Theme.popup.text
        opacity: 0.35
        font.family: Style.font.family
        font.pixelSize: Style.font.small
      }

      Repeater {
        model: 7

        Rectangle {
          id: cell

          required property int index

          readonly property date date: root.days[week.index * 7 + index]
          readonly property bool inMonth: date.getMonth() === root.month
          readonly property bool isToday: date.getFullYear() === root.today.getFullYear()
            && date.getMonth() === root.today.getMonth() && date.getDate() === root.today.getDate()

          width: week.width / 8
          height: Style.space(30)
          color: isToday ? Theme.popup.text : "transparent"

          Text {
            anchors.centerIn: parent
            text: cell.date.getDate()
            color: cell.isToday ? Theme.popup.background : Theme.popup.text
            opacity: cell.inMonth ? 1 : 0.3
            font.family: Style.font.family
            font.pixelSize: Style.font.body
            font.bold: cell.isToday
          }
        }
      }
    }
  }
}
