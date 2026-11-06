pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// What the shell remembers across restarts. Lives under ~/.local/state, never in the repo.
Singleton {
  id: root

  readonly property string dir: Quickshell.env("HOME") + "/.local/state/desk"

  property alias barHidden: data.barHidden
  property alias clockFormat: data.clockFormat
  property alias doNotDisturb: data.doNotDisturb
  property alias stayAwake: data.stayAwake
  property alias nightLight: data.nightLight
  property alias wallpaper: data.wallpaper

  FileView {
    id: file
    path: root.dir + "/shell.json"
    onAdapterUpdated: writeAdapter()
    onLoadFailed: function(error) {
      if (error === FileViewError.FileNotFound) writeAdapter()
    }

    JsonAdapter {
      id: data
      property bool barHidden: false
      property string clockFormat: ""
      property bool doNotDisturb: false
      property bool stayAwake: false
      property bool nightLight: false
      property string wallpaper: ""
    }
  }
}
