import QtQuick
import qs.Commons

// Opens the list of cities from Settings.worldClocks.
PanelButton {
  panelId: "worldclock"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot
  text: String.fromCodePoint(0xF01E7)
  tooltip: "World clock"
}
