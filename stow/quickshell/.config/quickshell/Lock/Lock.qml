import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import qs.Commons

// The lock screen. There's deliberately no way to unlock over IPC: only PAM can.
// If the shell crashes while locked, the screen stays locked, and the restarted shell finds
// the marker in the runtime directory and takes the lock over again.
Scope {
  id: root

  readonly property alias locked: session.locked
  readonly property bool secure: session.secure
  readonly property string marker: Quickshell.env("XDG_RUNTIME_DIR") + "/desk-locked"

  property string password: ""
  property string pending: ""
  property bool checking: false
  property string failure: ""
  property int attempts: 0

  function lock() {
    if (session.locked) return
    password = ""
    failure = ""
    attempts = 0
    session.locked = true
    Quickshell.execDetached(["touch", marker])
  }

  function unlock() {
    session.locked = false
    password = ""
    failure = ""
    Quickshell.execDetached(["rm", "-f", marker])
    Run.hypr('hl.dispatch(hl.dsp.dpms({ action = "enable" }))')
  }

  function submit() {
    if (checking || !password) return
    pending = password
    password = ""
    failure = ""
    checking = true
    if (!pam.start()) fail("Couldn't start authentication")
  }

  function fail(message) {
    checking = false
    pending = ""
    attempts += 1
    failure = message
  }

  PamContext {
    id: pam
    config: "desk-lock"

    onResponseRequiredChanged: {
      if (!responseRequired) return
      respond(root.pending)
      root.pending = ""
    }

    onCompleted: function(result) {
      if (result === PamResult.Success) {
        root.checking = false
        root.pending = ""
        root.unlock()
      } else {
        root.fail(root.attempts >= 8 ? "Wrong password. Too many tries locks this for 2 minutes" : "Wrong password")
      }
    }

    onError: root.fail("Couldn't authenticate")
  }

  WlSessionLock {
    id: session

    WlSessionLockSurface {
      id: surface

      color: Theme.background

      Image {
        anchors.fill: parent
        visible: status === Image.Ready
        source: Saved.wallpaper ? "file://" + Saved.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: surface.width
        sourceSize.height: surface.height
      }

      Rectangle {
        id: field

        anchors.centerIn: parent
        width: Style.space(381)
        height: Style.space(67)
        color: Theme.lock.background
        border.width: Style.space(3)
        border.color: root.failure ? Theme.lock.borderError : Theme.lock.borderActive

        TextInput {
          id: input

          anchors { fill: parent; leftMargin: Style.space(16); rightMargin: Style.space(16) }
          verticalAlignment: TextInput.AlignVCenter
          horizontalAlignment: TextInput.AlignHCenter
          echoMode: TextInput.Password
          passwordCharacter: "•"
          inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
          enabled: !root.checking
          focus: true
          clip: true
          color: root.failure ? Theme.lock.textError : Theme.lock.text
          selectionColor: Theme.lock.selection
          font.family: Style.font.family
          font.pixelSize: Style.font.heading * 1.33
          cursorVisible: !root.checking && !root.failure

          onTextEdited: {
            root.failure = ""
            root.password = text
          }

          // Every monitor has its own field, all showing the same password.
          Connections {
            target: root
            function onPasswordChanged() {
              if (input.text !== root.password) input.text = root.password
            }
          }

          Keys.onPressed: function(event) {
            // Waking a blanked display can stall long enough for a held key to repeat.
            if (event.isAutoRepeat && event.key !== Qt.Key_Backspace && event.key !== Qt.Key_Delete) {
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              root.submit()
              event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
              root.password = ""
              root.failure = ""
              event.accepted = true
            }
          }

          onEnabledChanged: if (enabled) forceActiveFocus()
          Component.onCompleted: forceActiveFocus()
        }

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          horizontalAlignment: Text.AlignHCenter
          visible: !input.text
          text: root.checking ? "Checking…" : (root.failure || "Enter password")
          textFormat: Text.PlainText
          color: root.failure ? Theme.lock.textError : Theme.lock.placeholder
          font.family: Style.font.family
          font.pixelSize: Style.font.heading
          elide: Text.ElideRight
        }
      }
    }
  }

  // Take the lock back if a previous run of the shell died holding it.
  Process {
    running: true
    command: ["test", "-e", root.marker]
    onExited: function(code) {
      if (code === 0) root.lock()
    }
  }

  IpcHandler {
    target: "lock"

    function lock(): void { root.lock() }
    function status(): string {
      if (!session.locked) return "unlocked"
      return session.secure ? "secure" : "locking"
    }
  }
}
