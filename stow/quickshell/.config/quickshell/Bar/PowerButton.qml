import QtQuick
import Quickshell.Services.UPower
import qs.Commons

// Battery level, or a plug on machines without a battery.
PanelButton {
  id: root

  panelId: "power"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot

  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: battery && battery.ready && battery.isLaptopBattery && battery.isPresent
  readonly property int percent: hasBattery ? Math.round(battery.percentage * 100) : 0
  readonly property bool charging: hasBattery && !UPower.onBattery

  active: hasBattery && !charging && percent <= 15

  text: {
    if (!hasBattery) return String.fromCodePoint(0xF06A5)
    var step = Math.min(9, Math.floor(percent / 10))
    // Battery glyphs run from 10% to 90% in order, with full on its own after them.
    if (charging) return String.fromCodePoint(0xF0084)
    return String.fromCodePoint(percent >= 95 ? 0xF0079 : 0xF007A + Math.max(0, step - 1))
  }

  tooltip: {
    if (!hasBattery) return "Power"
    return percent + "%" + (charging ? ", charging" : "")
  }
}
