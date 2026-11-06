pragma Singleton
import QtQuick
import Quickshell

// Sizes. All of them scale with Settings.fontBaseSize, so changing that one number
// resizes the whole shell in proportion.
Singleton {
  id: root

  readonly property real scale: Math.max(1 / 12, Settings.fontBaseSize / 12)

  function spaceReal(px) { return px * scale }
  function space(px) { return Math.max(px > 0 ? 1 : 0, Math.round(px * scale)) }
  function fontPx(multiple) { return Math.max(1, Math.round(Settings.fontBaseSize * multiple)) }

  readonly property int radius: 0
  readonly property int border: 2
  readonly property int edgeGap: 5

  // Short enough to feel instant. Shared so every surface moves at the same pace.
  readonly property int fast: 120
  readonly property int normal: 180

  readonly property QtObject font: QtObject {
    readonly property string family: "monospace"
    readonly property int caption: root.fontPx(0.833)
    readonly property int small: root.fontPx(0.917)
    readonly property int body: root.fontPx(1)
    readonly property int subtitle: root.fontPx(1.083)
    readonly property int title: root.fontPx(1.167)
    readonly property int heading: root.fontPx(1.333)
    readonly property int display: root.fontPx(2)
    readonly property int icon: root.fontPx(1.167)
    readonly property int iconLarge: root.fontPx(1.5)
  }

  readonly property QtObject bar: QtObject {
    readonly property int size: root.space(26)
    readonly property int iconSlot: root.space(27)
    readonly property int iconFont: root.space(13)
    readonly property int statusSlot: root.space(21)
  }

  readonly property QtObject spacing: QtObject {
    readonly property int xs: root.space(3)
    readonly property int sm: root.space(4)
    readonly property int md: root.space(6)
    readonly property int lg: root.space(8)
    readonly property int xl: root.space(12)
    readonly property int panel: root.space(18)
    readonly property int row: root.space(28)
    readonly property int control: root.space(28)
  }
}
