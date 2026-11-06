import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons

// What happens when you step away: screensaver, then lock, then the display goes off.
// Apps that inhibit idle, like a playing video, hold the first two back.
Scope {
  id: root

  required property var lockScreen

  property bool saverShown: false
  readonly property bool armed: !Saved.stayAwake && !lockScreen.locked

  function dpms(on) {
    Run.hypr('hl.dispatch(hl.dsp.dpms({ action = "' + (on ? "enable" : "disable") + '" }))')
  }

  IdleMonitor {
    enabled: root.armed && Settings.idleScreensaver > 0
    timeout: Settings.idleScreensaver
    respectInhibitors: true
    onIsIdleChanged: root.saverShown = isIdle
  }

  IdleMonitor {
    enabled: root.armed && Settings.idleLock > 0
    timeout: Settings.idleLock
    respectInhibitors: true
    onIsIdleChanged: if (isIdle) root.lockScreen.lock()
  }

  // A locked machine that's left alone doesn't need its display on. Nothing inhibits this.
  IdleMonitor {
    enabled: root.lockScreen.locked
    timeout: 60
    respectInhibitors: false
    onIsIdleChanged: root.dpms(!isIdle)
  }

  Variants {
    model: Quickshell.screens

    Screensaver {
      required property var modelData
      screen: modelData
      shown: root.saverShown && !root.lockScreen.locked
      onDismissed: root.saverShown = false
    }
  }

  IpcHandler {
    target: "idle"

    function screensaver(): void { root.saverShown = true }
    function toggleStayAwake(): void { Saved.stayAwake = !Saved.stayAwake }
    function state(): string {
      if (root.lockScreen.locked) return "locked"
      return root.saverShown ? "screensaver" : "active"
    }
  }
}
