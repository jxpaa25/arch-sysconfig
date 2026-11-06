import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs.Commons
import qs.Ui

// UNTESTED until it runs on real hardware; the VM has no Bluetooth adapter.
// Turn the radio on or off, scan, and connect. Delete forgets a device.
PanelBase {
  id: root

  title: "Bluetooth"

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property var devices: {
    var values = adapter && adapter.devices ? adapter.devices.values.slice() : []
    return values.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.paired !== b.paired) return a.paired ? -1 : 1
      return (a.name || "").localeCompare(b.name || "")
    })
  }

  function iconFor(device) {
    var icon = String(device.icon || "")
    if (icon.indexOf("audio") !== -1) return String.fromCodePoint(0xF02CB)
    if (icon.indexOf("keyboard") !== -1) return String.fromCodePoint(0xF030C)
    if (icon.indexOf("mouse") !== -1) return String.fromCodePoint(0xF037D)
    if (icon.indexOf("phone") !== -1) return String.fromCodePoint(0xF03F2)
    return String.fromCodePoint(0xF00AF)
  }

  // Stop scanning when the panel closes.
  Component.onDestruction: if (adapter && adapter.discovering) adapter.discovering = false

  PanelRow {
    icon: String.fromCodePoint(0xF00AF)
    label: "Bluetooth"
    toggled: root.adapter && root.adapter.enabled ? 1 : 0
    onClicked: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
  }

  PanelRow {
    visible: !!root.adapter && root.adapter.enabled
    icon: String.fromCodePoint(0xF0349)
    label: "Scan for devices"
    toggled: root.adapter && root.adapter.discovering ? 1 : 0
    onClicked: root.adapter.discovering = !root.adapter.discovering
  }

  PanelHeading { text: "Devices"; visible: root.devices.length > 0 }

  Repeater {
    model: !!root.adapter && root.adapter.enabled ? root.devices : []

    PanelRow {
      id: row
      required property var modelData
      property bool connectOnPair: false

      icon: root.iconFor(modelData)
      label: modelData.name || modelData.address
      selected: modelData.connected
      detail: {
        if (modelData.pairing) return "Pairing…"
        if (modelData.connected) return "Connected"
        return modelData.paired ? "Paired" : ""
      }
      trailing: modelData.batteryAvailable ? Math.round(modelData.battery * 100) + "%" : ""

      onClicked: {
        if (modelData.connected) {
          modelData.disconnect()
        } else if (modelData.paired) {
          modelData.connect()
        } else {
          row.connectOnPair = true
          modelData.trusted = true
          modelData.pair()
        }
      }
      onSecondaryAction: if (modelData.paired) modelData.forget()

      Connections {
        target: row.modelData
        function onPairedChanged() {
          if (row.modelData.paired && row.connectOnPair) row.modelData.connect()
          row.connectOnPair = false
        }
      }
    }
  }
}
