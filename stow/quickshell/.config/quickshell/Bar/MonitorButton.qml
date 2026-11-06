import QtQuick
import qs.Commons

// Display settings: brightness, scale and laptop display controls.
PanelButton {
  panelId: "monitor"
  fontSize: Style.bar.iconFont
  fixedWidth: Style.bar.iconSlot
  text: String.fromCodePoint(0xF0379)
  tooltip: "Display"
}
