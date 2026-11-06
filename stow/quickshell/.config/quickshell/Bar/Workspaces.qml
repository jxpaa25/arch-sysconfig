import QtQuick
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Workspace slots 1-10. With paired monitors (see hypr/bindings/slots.lua), slot N means
// workspace N together with workspace N+10, so a slot counts as occupied if either one is.
Row {
  id: root

  spacing: Style.space(1)
  rightPadding: Style.spaceReal(1.5)

  function slotOf(id) {
    return id >= 1 && id <= 20 ? (id - 1) % 10 + 1 : -1
  }

  function slotOccupied(slot) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (root.slotOf(values[i].id) === slot && values[i].toplevels.values.length > 0) return true
    }
    return false
  }

  Repeater {
    model: 10

    BarButton {
      required property int index

      readonly property int slot: index + 1
      readonly property bool focused: Hyprland.focusedWorkspace !== null && root.slotOf(Hyprland.focusedWorkspace.id) === slot

      text: focused ? String.fromCodePoint(0xF14FB) : (slot === 10 ? "0" : String(slot))
      labelOpacity: focused || root.slotOccupied(slot) ? 1 : 0.5
      fixedWidth: Style.space(20)

      // Same as SUPER + number: moves every paired monitor, and focus stays put.
      onClicked: Run.hypr("grouped_workspaces.focus_slot(" + slot + ")")
    }
  }
}
