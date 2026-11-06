import QtQuick
import Quickshell
import Quickshell.Networking
import qs.Commons
import qs.Ui

// Wired and Wi-Fi state, and joining Wi-Fi networks. A network you've joined before connects
// straight away. A secured new one asks for its password here. Delete forgets a network.
PanelBase {
  id: root

  title: "Network"
  subtitle: {
    switch (Networking.connectivity) {
    case NetworkConnectivity.Full: return "Online"
    case NetworkConnectivity.Limited: return "Limited connectivity"
    case NetworkConnectivity.Portal: return "Sign-in needed"
    case NetworkConnectivity.None: return "Offline"
    }
    return ""
  }

  readonly property var devices: Networking.devices ? Networking.devices.values : []
  readonly property var wifi: devices.filter(function(device) { return device.type === DeviceType.Wifi })[0] || null
  readonly property var wired: devices.filter(function(device) { return device.type === DeviceType.Wired })

  readonly property var networks: {
    if (!wifi || !wifi.networks) return []
    return wifi.networks.values.slice().sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.known !== b.known) return a.known ? -1 : 1
      return b.signalStrength - a.signalStrength
    })
  }

  property var askingFor: null
  property string failed: ""

  function signalIcon(strength) {
    if (strength > 0.75) return String.fromCodePoint(0xF0928)
    if (strength > 0.5) return String.fromCodePoint(0xF0925)
    if (strength > 0.25) return String.fromCodePoint(0xF0922)
    return String.fromCodePoint(0xF091F)
  }

  function join(network) {
    failed = ""
    if (network.connected) network.disconnect()
    else if (network.known || network.security === WifiSecurityType.Open) network.connect()
    else {
      askingFor = network
      passwordInput.text = ""
      passwordInput.forceActiveFocus()
    }
  }

  // Scan only while the panel is open.
  Binding {
    target: root.wifi
    property: "scannerEnabled"
    value: true
    when: root.wifi !== null
  }

  Repeater {
    model: root.wired

    PanelRow {
      required property var modelData
      icon: String.fromCodePoint(0xF0200)
      label: modelData.name
      detail: modelData.connected ? "Connected" : "Not connected"
      selected: modelData.connected
      interactive: false
    }
  }

  PanelRow {
    visible: root.wifi !== null
    icon: String.fromCodePoint(0xF05A9)
    label: "Wi-Fi"
    toggled: Networking.wifiEnabled ? 1 : 0
    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled
  }

  PanelHeading { text: root.failed; visible: root.failed !== "" }

  Repeater {
    model: Networking.wifiEnabled ? root.networks : []

    PanelRow {
      required property var modelData
      icon: root.signalIcon(modelData.signalStrength)
      label: modelData.name
      selected: modelData.connected
      detail: modelData.stateChanging ? ConnectionState.toString(modelData.state)
        : (modelData.connected ? "Connected" : (modelData.known ? "Saved" : ""))
      trailing: modelData.security === WifiSecurityType.Open ? "" : String.fromCodePoint(0xF033E)
      onClicked: root.join(modelData)
      onSecondaryAction: if (modelData.known) modelData.forget()

      Connections {
        target: modelData
        function onConnectionFailed(reason) {
          root.failed = modelData.name + ": " + ConnectionFailReason.toString(reason)
        }
      }
    }
  }

  // The password prompt for a new network. Keys go to this field while it has focus.
  Rectangle {
    visible: root.askingFor !== null
    width: parent ? parent.width : 0
    height: Style.space(38)
    color: Theme.control.fill
    border.color: Theme.control.border
    border.width: 1

    TextInput {
      id: passwordInput

      anchors { fill: parent; leftMargin: Style.spacing.lg; rightMargin: Style.spacing.lg }
      verticalAlignment: TextInput.AlignVCenter
      echoMode: TextInput.Password
      passwordCharacter: "•"
      inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
      clip: true
      color: Theme.popup.text
      font.family: Style.font.family
      font.pixelSize: Style.font.title

      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
          if (root.askingFor && text) root.askingFor.connectWithPsk(text)
          text = ""
          root.askingFor = null
          event.accepted = true
        } else if (event.key === Qt.Key_Escape) {
          text = ""
          root.askingFor = null
          event.accepted = true
        }
      }
    }

    Text {
      anchors.fill: passwordInput
      verticalAlignment: Text.AlignVCenter
      visible: !passwordInput.text
      text: root.askingFor ? "Password for " + root.askingFor.name : ""
      textFormat: Text.PlainText
      color: Theme.popup.text
      opacity: 0.58
      font: passwordInput.font
    }
  }

  PanelRow {
    icon: String.fromCodePoint(0xF0493)
    label: "Connection settings"
    onClicked: {
      Panels.close()
      Quickshell.execDetached(["launch-tui", "--app-id=org.desk.float", "nmtui"])
    }
  }
}
