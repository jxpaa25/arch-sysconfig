import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Asks for your password when an app needs extra rights. The password goes straight to
// polkit and the field is cleared as soon as it's sent.
Scope {
  id: root

  readonly property var flow: agent.flow

  function cancel() {
    if (flow) flow.cancelAuthenticationRequest()
  }

  function submit() {
    if (!flow || !input.text || !flow.isResponseRequired) return
    var response = input.text
    input.text = ""
    flow.submit(response)
  }

  PolkitAgent {
    id: agent
    onIsActiveChanged: {
      input.text = ""
      if (isActive) focusLater.restart()
    }
  }

  Timer {
    id: focusLater
    interval: 50
    onTriggered: input.forceActiveFocus()
  }

  Overlay {
    id: overlay

    shown: agent.isActive
    scrim: Theme.polkit.scrim
    WlrLayershell.namespace: "desk-polkit"
    onDismissed: root.cancel()

    Rectangle {
      anchors.centerIn: parent
      width: Style.space(420)
      height: content.implicitHeight + Style.spacing.panel * 2
      color: Theme.polkit.background
      border.color: root.flow && root.flow.failed ? Theme.polkit.borderError : Theme.polkit.border
      border.width: Style.border
      radius: Style.radius

      // Clicks on the card don't count as clicking away.
      MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
      }

      Column {
        id: content

        anchors { left: parent.left; right: parent.right; top: parent.top; margins: Style.spacing.panel }
        spacing: Style.spacing.lg

        Text {
          width: parent.width
          text: root.flow ? root.flow.message : ""
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: Theme.polkit.text
          font.family: Style.font.family
          font.pixelSize: Style.font.title
        }

        Text {
          width: parent.width
          visible: !!root.flow && (root.flow.failed || root.flow.supplementaryMessage !== "")
          text: !root.flow ? "" : (root.flow.supplementaryMessage || "Wrong password")
          textFormat: Text.PlainText
          wrapMode: Text.Wrap
          color: Theme.polkit.textError
          font.family: Style.font.family
          font.pixelSize: Style.font.body
        }

        Rectangle {
          width: parent.width
          height: Style.space(42)
          color: Theme.control.fill
          border.color: Theme.control.border
          border.width: 1

          TextInput {
            id: input

            anchors { fill: parent; leftMargin: Style.spacing.xl; rightMargin: Style.spacing.xl }
            verticalAlignment: TextInput.AlignVCenter
            echoMode: !!root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            clip: true
            color: Theme.polkit.text
            selectionColor: Theme.withAlpha(Theme.polkit.accent, 0.45)
            font.family: Style.font.family
            font.pixelSize: Style.font.title

            Keys.onPressed: function(event) {
              if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.submit()
                event.accepted = true
              } else if (event.key === Qt.Key_Escape) {
                root.cancel()
                event.accepted = true
              }
            }
          }

          Text {
            anchors.fill: input
            verticalAlignment: Text.AlignVCenter
            visible: !input.text
            text: root.flow && root.flow.inputPrompt ? root.flow.inputPrompt.replace(/:\s*$/, "") : "Password"
            textFormat: Text.PlainText
            color: Theme.polkit.text
            opacity: 0.58
            font: input.font
          }
        }
      }
    }
  }
}
