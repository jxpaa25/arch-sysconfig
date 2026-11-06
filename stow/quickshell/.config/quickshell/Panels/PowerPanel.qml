import QtQuick
import Quickshell.Services.UPower
import qs.Commons
import qs.Ui

// Battery state and the power profile. The battery rows are UNTESTED until they run on real
// hardware; the VM has none.
PanelBase {
  id: root

  title: "Power"

  readonly property var battery: UPower.displayDevice
  readonly property bool hasBattery: !!battery && battery.ready && battery.isLaptopBattery && battery.isPresent
  subtitle: UPower.onBattery ? "On battery" : "Plugged in"

  function duration(seconds) {
    if (seconds <= 0) return ""
    var hours = Math.floor(seconds / 3600)
    var minutes = Math.floor(seconds % 3600 / 60)
    return (hours ? hours + "h " : "") + minutes + "m"
  }

  PanelRow {
    visible: root.hasBattery
    interactive: false
    icon: String.fromCodePoint(0xF0079)
    label: root.hasBattery ? Math.round(root.battery.percentage * 100) + "%" : ""
    detail: {
      if (!root.hasBattery) return ""
      switch (root.battery.state) {
      case UPowerDeviceState.Charging:
        return "Charging, full in " + root.duration(root.battery.timeToFull)
      case UPowerDeviceState.Discharging:
        return root.duration(root.battery.timeToEmpty) + " left"
      case UPowerDeviceState.FullyCharged:
        return "Fully charged"
      }
      return UPowerDeviceState.toString(root.battery.state)
    }
    trailing: root.hasBattery && root.battery.healthSupported ? "Health " + Math.round(root.battery.healthPercentage) + "%" : ""
  }

  PanelHeading { text: "Power profile" }

  PanelRow {
    icon: String.fromCodePoint(0xF032A)
    label: "Power saver"
    selected: PowerProfiles.profile === PowerProfile.PowerSaver
    onClicked: PowerProfiles.profile = PowerProfile.PowerSaver
  }

  PanelRow {
    icon: String.fromCodePoint(0xF05D1)
    label: "Balanced"
    selected: PowerProfiles.profile === PowerProfile.Balanced
    onClicked: PowerProfiles.profile = PowerProfile.Balanced
  }

  PanelRow {
    visible: PowerProfiles.hasPerformanceProfile
    icon: String.fromCodePoint(0xF04C5)
    label: "Performance"
    selected: PowerProfiles.profile === PowerProfile.Performance
    onClicked: PowerProfiles.profile = PowerProfile.Performance
  }
}
