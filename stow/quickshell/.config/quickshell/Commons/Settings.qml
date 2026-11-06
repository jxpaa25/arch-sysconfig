pragma Singleton
import QtQuick
import Quickshell

// Your preferences, in one place. Change them here. Anything the shell changes while it
// runs, such as do-not-disturb, lives in Saved instead, so it never dirties this repo.
Singleton {
  // Every size in the shell scales from this. 12 is the size the spacing was designed at.
  readonly property int fontBaseSize: 10

  // Bar clock: first entry is the default, right click walks the rest. "ww" is the ISO week.
  readonly property var clockFormats: [
    "dd.MM HH:mm",
    "d MMMM 'W'ww yyyy",
    "dddd HH:mm",
    "HH:mm",
    "yyyy-MM-dd HH:mm"
  ]

  readonly property var worldClocks: [
    { name: "Belgrade", zone: "Europe/Belgrade" },
    { name: "Dubai", zone: "Asia/Dubai" },
    { name: "Tokyo", zone: "Asia/Tokyo" },
    { name: "Los Angeles", zone: "America/Los_Angeles" },
    { name: "New York", zone: "America/New_York" }
  ]

  // Seconds of inactivity before each step. 0 turns that step off.
  readonly property int idleScreensaver: 150
  readonly property int idleLock: 300
}
