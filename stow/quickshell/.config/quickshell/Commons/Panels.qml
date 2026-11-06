pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which bar panel is open, and which bar widget it hangs from. There's one bar per monitor,
// so each widget registers per screen and a hotkey opens the copy on the focused monitor.
Singleton {
  id: root

  // Panel ids in bar order, for the SUPER CTRL + number binds and for Tab inside a panel.
  readonly property var order: ["bluetooth", "network", "audio", "monitor", "power", "clock", "worldclock"]

  property string current: ""
  property var anchor: null
  property var screen: null
  property var targets: ({})

  function register(id, screenName, item) {
    targets[id + "@" + screenName] = item
  }

  function unregister(id, screenName, item) {
    if (targets[id + "@" + screenName] === item) delete targets[id + "@" + screenName]
  }

  function screenByName(name) {
    var screens = Quickshell.screens
    for (var i = 0; i < screens.length; i++) {
      if (screens[i].name === name) return screens[i]
    }
    return screens.length ? screens[0] : null
  }

  function focusedScreenName() {
    return Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : ""
  }

  function targetFor(id) {
    var target = targets[id + "@" + focusedScreenName()]
    if (target) return target
    for (var key in targets) {
      if (key.indexOf(id + "@") === 0) return targets[key]
    }
    return null
  }

  // Only the ones you can see on the bar. A machine with no Bluetooth has no such panel.
  function available() {
    return order.filter(function(id) {
      var target = root.targetFor(id)
      return target && target.visible
    })
  }

  function open(id, item) {
    var target = item || targetFor(id)
    if (!target) return
    anchor = target
    screen = target.QsWindow && target.QsWindow.window ? target.QsWindow.window.screen : screenByName(focusedScreenName())
    current = id
  }

  function close() {
    current = ""
    anchor = null
  }

  function toggle(id, item) {
    if (current === id && (!item || item === anchor)) close()
    else open(id, item)
  }

  function toggleAt(position) {
    var id = available()[position - 1]
    if (id) toggle(id)
  }

  function step(delta) {
    var ids = available()
    if (!ids.length) return
    var at = ids.indexOf(current)
    open(ids[(at + delta + ids.length) % ids.length])
  }
}
