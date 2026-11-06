pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Things that run outside the shell and that the shell shows or controls.
Singleton {
  id: root

  // gpu-screen-recorder, started and stopped by the screen-record script.
  property bool recording: false

  function setNightLight(on) {
    Saved.nightLight = on
    // hyprsunset's identity keeps the screen untouched, so "off" is just another setting.
    Run.sh(on ? "hyprctl hyprsunset temperature 4000" : "hyprctl hyprsunset identity")
  }

  function toggleNightLight() {
    setNightLight(!Saved.nightLight)
  }

  // Pick up whatever the last session left on.
  Component.onCompleted: {
    if (Saved.nightLight) startupNight.restart()
  }

  Timer {
    id: startupNight
    interval: 2000
    onTriggered: root.setNightLight(Saved.nightLight)
  }

  Process {
    id: recorderCheck
    command: ["pgrep", "-x", "gpu-screen-recorder"]
    onExited: function(code) { root.recording = code === 0 }
  }

  Timer {
    interval: 2000
    running: true
    repeat: true
    onTriggered: if (!recorderCheck.running) recorderCheck.running = true
  }

  IpcHandler {
    target: "status"

    function refresh(): void { recorderCheck.running = true }
    function nightLight(): void { root.toggleNightLight() }
  }
}
