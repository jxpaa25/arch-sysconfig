import QtQuick
import qs.Commons

// A small heading between groups of rows.
Text {
  width: parent ? parent.width : 0
  topPadding: Style.spacing.lg
  bottomPadding: Style.spacing.xs
  textFormat: Text.PlainText
  color: Theme.popup.text
  opacity: 0.55
  font.family: Style.font.family
  font.pixelSize: Style.font.small
  font.capitalization: Font.AllLowercase
}
