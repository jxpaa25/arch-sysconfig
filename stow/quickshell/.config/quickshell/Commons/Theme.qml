pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Colours from the current theme: colors.toml for the palette, shell.toml for each surface.
// theme-set re-points ~/.local/state/theme/current, then calls reload() over IPC, because a
// file watcher doesn't notice a symlink changing where it points.
Singleton {
  id: root

  readonly property string dir: Quickshell.env("HOME") + "/.local/state/theme/current"

  property var palette: ({})
  property var surfaces: ({})
  // "dark" or "light", taken from which end of the range the background sits at.
  readonly property bool dark: background.hslLightness < 0.5

  readonly property color foreground: colorOf(palette.foreground, "#ffffff")
  readonly property color background: colorOf(palette.background, "#000000")
  readonly property color accent: colorOf(palette.accent, "#8d8d8d")
  readonly property color urgent: colorOf(palette.red, "#a4a4a4")
  readonly property color muted: colorOf(palette.muted, "#7a7a7a")
  readonly property color selection: colorOf(palette.selection, "#1a1a1a")

  function reload() {
    colorsFile.reload()
    shellFile.reload()
  }

  // A small TOML reader, enough for the flat files the themes use. Sections become
  // "section.key" names.
  function parseToml(text) {
    var out = {}
    var section = ""
    var lines = String(text || "").split("\n")
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim()
      if (!line || line.charAt(0) === "#") continue
      var heading = line.match(/^\[(.+)\]$/)
      if (heading) {
        section = heading[1].trim() + "."
        continue
      }
      var pair = line.match(/^([\w-]+)\s*=\s*(?:"([^"]*)"|([^#]*))/)
      if (pair) out[section + pair[1]] = pair[2] !== undefined ? pair[2] : pair[3].trim()
    }
    return out
  }

  // A surface value is a colour, a palette role, or the name of another value.
  function resolve(value, fallback) {
    var token = String(value === undefined ? "" : value).trim()
    for (var hops = 0; hops < 4 && surfaces[token] !== undefined; hops++) token = surfaces[token]
    switch (token) {
      case "": return fallback
      case "foreground": case "text": return foreground
      case "background": return background
      case "accent": return accent
      case "urgent": return urgent
      case "muted": return muted
      case "transparent": return Qt.rgba(0, 0, 0, 0)
    }
    return token.charAt(0) === "#" ? token : fallback
  }

  function colorOf(value, fallback) {
    return Qt.color(value && String(value).charAt(0) === "#" ? value : fallback)
  }

  function pick(key, fallback) {
    return Qt.color(resolve(surfaces[key], fallback))
  }

  // A surface colour with its "-alpha" companion applied.
  function composed(key, alphaKey, fallback, fallbackAlpha) {
    var base = pick(key, fallback)
    var alpha = Number(surfaces[alphaKey])
    return Qt.rgba(base.r, base.g, base.b, isFinite(alpha) && surfaces[alphaKey] !== undefined ? alpha : fallbackAlpha)
  }

  function withAlpha(color, alpha) {
    var c = Qt.color(color)
    return Qt.rgba(c.r, c.g, c.b, alpha)
  }

  readonly property QtObject bar: QtObject {
    readonly property color background: root.composed("bar.background", "bar.background-alpha", root.background, 1)
    readonly property color text: root.pick("bar.text", root.foreground)
    readonly property color active: root.pick("bar.active", root.urgent)
  }

  readonly property QtObject popup: QtObject {
    readonly property color background: root.composed("popups.background", "popups.background-alpha", root.background, 1)
    readonly property color text: root.pick("popups.text", root.foreground)
    readonly property color border: root.composed("popups.border", "popups.border-alpha", root.accent, 1)
  }

  readonly property QtObject tooltip: QtObject {
    readonly property color background: root.composed("tooltip.background", "tooltip.background-alpha", root.background, 1)
    readonly property color text: root.pick("tooltip.text", root.foreground)
    readonly property color border: root.composed("tooltip.border", "tooltip.border-alpha", root.foreground, 1)
  }

  readonly property QtObject notification: QtObject {
    readonly property color background: root.composed("notifications.background", "notifications.background-alpha", root.background, 1)
    readonly property color text: root.pick("notifications.text", root.foreground)
    readonly property color border: root.composed("notifications.border", "notifications.border-alpha", root.accent, 1)
  }

  readonly property QtObject menu: QtObject {
    readonly property color background: root.composed("menu.background", "menu.background-alpha", root.background, 1)
    readonly property color text: root.pick("menu.text", root.foreground)
    readonly property color border: root.composed("menu.border", "menu.border-alpha", root.foreground, 1)
    readonly property color scrim: root.composed("menu.scrim", "menu.scrim-alpha", root.background, 0.5)
    readonly property color selectedBackground: root.composed("menu.selected-background", "menu.selected-background-alpha", root.foreground, 1)
    readonly property color selectedText: root.pick("menu.selected-text", root.background)
    readonly property color selectedBorder: root.composed("menu.selected-border", "menu.selected-border-alpha", root.foreground, 0)
  }

  readonly property QtObject polkit: QtObject {
    readonly property color background: root.composed("polkit.background", "polkit.background-alpha", root.background, 1)
    readonly property color text: root.pick("polkit.text", root.foreground)
    readonly property color textError: root.pick("polkit.text-error", root.urgent)
    readonly property color border: root.composed("polkit.border", "polkit.border-alpha", root.accent, 1)
    readonly property color borderError: root.pick("polkit.border-error", root.urgent)
    readonly property color accent: root.pick("polkit.accent", root.accent)
    readonly property color scrim: root.composed("polkit.scrim", "polkit.scrim-alpha", root.background, 0.5)
  }

  readonly property QtObject lock: QtObject {
    readonly property color background: root.composed("lock.background", "lock.background-alpha", root.background, 0.8)
    readonly property color text: root.pick("lock.text", root.foreground)
    readonly property color placeholder: root.pick("lock.placeholder", root.muted)
    readonly property color textError: root.pick("lock.text-error", root.urgent)
    readonly property color border: root.composed("lock.border", "lock.border-alpha", root.accent, 1)
    readonly property color borderActive: root.composed("lock.border-active", "lock.border-alpha", root.accent, 1)
    readonly property color borderError: root.pick("lock.border-error", root.urgent)
    readonly property color selection: root.composed("lock.selection", "lock.selection-alpha", root.accent, 0.45)
  }

  readonly property QtObject control: QtObject {
    readonly property color fill: root.withAlpha(root.foreground, 0.04)
    readonly property color hoverFill: root.withAlpha(root.foreground, 0.08)
    readonly property color selectedFill: root.withAlpha(root.foreground, 0.18)
    readonly property color pressedFill: root.withAlpha(root.foreground, 0.22)
    readonly property color border: root.withAlpha(root.foreground, 0.4)
    readonly property color hoverBorder: root.withAlpha(root.foreground, 0.25)
  }

  FileView {
    id: colorsFile
    path: root.dir + "/colors.toml"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.palette = root.parseToml(text())
  }

  FileView {
    id: shellFile
    path: root.dir + "/shell.toml"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.surfaces = root.parseToml(text())
  }
}
