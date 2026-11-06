pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland

// Which bar panel is open, and which bar widget it hangs from. There's one bar per monitor,
// so each widget registers per screen and a hotkey opens the copy on the focused monitor.
Singleton {
  id: root

  // Panel ids in bar order, for the SUPER CTRL + number binds.
  readonly property var order: ["bluetooth", "network", "audio", "monitor", "power", "clock", "worldclock"]

  property string current: ""
  property var anchor: null
  property var screen: null
  property var anchors: ({})

  function register(id, screenName, item) {
    anchors[id + "@" + screenName] = item
  }

  function unregister(id, screenName, item) {
    if (anchors[id + "@" + screenName] === item) delete anchors[id + "@" + screenName]
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

  function open(id, item) {
    var name = focusedScreenName()
    var target = item || anchors[id + "@" + name]
    if (!target) {
      for (var key in anchors) {
        if (key.indexOf(id + "@") === 0) {
          target = anchors[key]
          break
        }
      }
    }
    if (!target) return
    anchor = target
    screen = target.QsWindow && target.QsWindow.window ? target.QsWindow.window.screen : screenByName(name)
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
    var id = order[position - 1]
    if (id) toggle(id)
  }
}
