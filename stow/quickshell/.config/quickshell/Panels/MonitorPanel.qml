import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// Brightness where the hardware has it, each monitor's mode and scale, and night light.
// Left and Right on a monitor step the focused monitor's scale. Brightness and the laptop
// display controls are UNTESTED until they run on real hardware.
PanelBase {
  id: root

  title: "Display"

  property var monitors: []
  property real brightness: -1
  property bool laptop: false
  property bool mirrored: false
  property bool internalOff: false

  function refresh() {
    if (!monitorQuery.running) monitorQuery.running = true
    if (!facts.running) facts.running = true
  }

  Component.onCompleted: {
    refresh()
    brightnessQuery.running = true
  }

  Process {
    id: monitorQuery
    command: ["hyprctl", "monitors", "-j"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          root.monitors = JSON.parse(text)
        } catch (e) {
          root.monitors = []
        }
      }
    }
  }

  Process {
    id: brightnessQuery
    command: ["brightnessctl", "-m", "--class=backlight"]
    stdout: StdioCollector {
      onStreamFinished: {
        var percent = parseInt((text.split(",")[3] || "").replace("%", ""))
        root.brightness = isNaN(percent) ? -1 : percent / 100
      }
    }
  }

  Process {
    id: facts
    command: ["bash", "-c", "compgen -G '/sys/class/power_supply/BAT*' >/dev/null && echo laptop; [[ -f ~/.local/state/desk/toggles/internal-monitor-disable.lua ]] && echo off; [[ -f ~/.local/state/desk/toggles/internal-monitor-mirror.lua ]] && echo mirror; true"]
    stdout: StdioCollector {
      onStreamFinished: {
        root.laptop = text.indexOf("laptop") !== -1
        root.internalOff = text.indexOf("off") !== -1
        root.mirrored = text.indexOf("mirror") !== -1
      }
    }
  }

  Timer {
    id: refreshSoon
    interval: 400
    onTriggered: root.refresh()
  }

  PanelSlider {
    visible: root.brightness >= 0
    icon: String.fromCodePoint(0xF00E0)
    label: "Brightness"
    value: Math.max(0, root.brightness)
    onMoved: function(next) {
      root.brightness = next
      Quickshell.execDetached(["brightnessctl", "--class=backlight", "set", Math.max(1, Math.round(next * 100)) + "%"])
    }
  }

  Repeater {
    model: root.monitors

    PanelRow {
      required property var modelData
      icon: String.fromCodePoint(0xF0379)
      label: modelData.name
      detail: modelData.width + "×" + modelData.height + " at " + Math.round(modelData.refreshRate) + " Hz"
      trailing: modelData.scale + "×"
      selected: modelData.focused
      interactive: false
      onAdjusted: function(delta) {
        Quickshell.execDetached(["monitor-scaling", delta > 0 ? "up" : "down"])
        refreshSoon.restart()
      }
    }
  }

  PanelRow {
    icon: String.fromCodePoint(0xF050E)
    label: "Night light"
    toggled: Saved.nightLight ? 1 : 0
    onClicked: Status.toggleNightLight()
  }

  PanelRow {
    visible: root.laptop
    icon: String.fromCodePoint(0xF06A7)
    label: "Laptop display"
    toggled: root.internalOff ? 0 : 1
    onClicked: {
      Quickshell.execDetached(["monitor-internal", "toggle"])
      refreshSoon.restart()
    }
  }

  PanelRow {
    visible: root.laptop
    icon: String.fromCodePoint(0xF0379)
    label: "Mirror displays"
    toggled: root.mirrored ? 1 : 0
    onClicked: {
      Quickshell.execDetached(["monitor-internal", "mirror"])
      refreshSoon.restart()
    }
  }
}
