import QtQuick
import Quickshell.Bluetooth
import qs.Commons

// Bluetooth state. Hidden on machines with no adapter. Right click turns the radio on or off.
PanelButton {
  id: root

  panelId: "bluetooth"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var connectedDevices: {
    var values = Bluetooth.devices ? Bluetooth.devices.values : []
    return values.filter(function(device) { return device.connected })
  }

  visible: adapter !== null
  width: visible ? implicitWidth : 0

  text: {
    if (!adapter || !adapter.enabled) return String.fromCodePoint(0xF00B2)
    return connectedDevices.length ? String.fromCodePoint(0xF00B1) : String.fromCodePoint(0xF00AF)
  }

  tooltip: {
    if (!adapter || !adapter.enabled) return "Bluetooth off"
    if (!connectedDevices.length) return "Bluetooth on"
    return connectedDevices.map(function(device) { return device.name }).join(", ")
  }

  onClicked: function(button) {
    if (button === Qt.RightButton && root.adapter) root.adapter.enabled = !root.adapter.enabled
  }
}
