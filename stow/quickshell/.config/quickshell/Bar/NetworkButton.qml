import QtQuick
import Quickshell.Networking
import qs.Commons

// Wi-Fi or wired state, read from NetworkManager.
PanelButton {
  id: root

  panelId: "network"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot

  readonly property var devices: Networking.devices ? Networking.devices.values : []
  readonly property var connected: {
    for (var i = 0; i < devices.length; i++) {
      if (devices[i].connected) return devices[i]
    }
    return null
  }
  readonly property bool wifi: connected !== null && connected.type === DeviceType.Wifi

  readonly property var wifiNetwork: {
    if (!wifi || !connected.networks) return null
    var networks = connected.networks.values
    for (var i = 0; i < networks.length; i++) {
      if (networks[i].connected) return networks[i]
    }
    return null
  }

  text: {
    if (!connected) return String.fromCodePoint(0xF092D)
    if (!wifi) return String.fromCodePoint(0xF0200)
    var strength = wifiNetwork ? wifiNetwork.signalStrength : 0
    if (strength > 0.75) return String.fromCodePoint(0xF0928)
    if (strength > 0.5) return String.fromCodePoint(0xF0925)
    if (strength > 0.25) return String.fromCodePoint(0xF0922)
    return String.fromCodePoint(0xF091F)
  }

  tooltip: {
    if (!connected) return "Disconnected"
    if (wifiNetwork) return wifiNetwork.name
    return connected.name
  }
}
