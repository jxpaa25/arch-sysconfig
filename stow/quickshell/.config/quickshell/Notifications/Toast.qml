import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.Commons

// One notification. Click to act on it, right click to dismiss it.
// Hovering pauses its countdown. Critical ones stay until dismissed.
Rectangle {
  id: root

  required property var notification

  signal activated

  readonly property bool critical: notification.urgency === NotificationUrgency.Critical
  // A sender's own timeout wins. Otherwise low goes first and critical never does.
  readonly property int duration: {
    if (critical) return 0
    if (notification.expireTimeout > 0) return notification.expireTimeout * 1000
    return notification.urgency === NotificationUrgency.Low ? 3000 : 5000
  }
  property int remaining: duration

  readonly property string imagePath: notification.image
    || (notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "")
  readonly property var buttons: notification.actions.filter(function(action) {
    return action.identifier !== "default"
  })

  implicitHeight: content.implicitHeight + Style.space(10) * 2
  color: Theme.notification.background
  border.color: critical ? Theme.urgent : Theme.notification.border
  border.width: Style.border

  Timer {
    interval: 100
    repeat: true
    running: root.duration > 0 && !mouse.containsMouse
    onTriggered: {
      root.remaining -= interval
      if (root.remaining <= 0) root.notification.expire()
    }
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    onClicked: function(event) {
      if (event.button === Qt.RightButton) root.notification.dismiss()
      else root.activated()
    }
  }

  Row {
    id: content
    anchors { left: parent.left; right: parent.right; top: parent.top }
    anchors { leftMargin: Style.space(14); rightMargin: Style.space(12); topMargin: Style.space(10) }
    spacing: Style.space(10)

    Image {
      id: picture
      visible: status === Image.Ready
      width: visible ? Style.space(40) : 0
      height: Style.space(40)
      source: root.imagePath
      sourceSize.width: width * 2
      sourceSize.height: height * 2
      fillMode: Image.PreserveAspectFit
      asynchronous: true
    }

    Column {
      width: parent.width - (picture.visible ? picture.width + parent.spacing : 0)
      spacing: Style.space(3)

      Text {
        width: parent.width
        text: root.notification.summary || root.notification.appName
        textFormat: Text.PlainText
        color: Theme.notification.text
        font.family: Style.font.family
        font.pixelSize: Style.font.title
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: text !== ""
        text: root.notification.body
        textFormat: Text.PlainText
        color: Theme.notification.text
        opacity: 0.8
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        wrapMode: Text.Wrap
        maximumLineCount: 4
        elide: Text.ElideRight
      }

      Row {
        visible: root.buttons.length > 0
        topPadding: Style.space(4)
        spacing: Style.space(6)

        Repeater {
          model: root.buttons

          Rectangle {
            required property var modelData

            implicitWidth: buttonLabel.implicitWidth + Style.space(16)
            implicitHeight: buttonLabel.implicitHeight + Style.space(8)
            color: buttonMouse.containsMouse ? Theme.control.hoverFill : Theme.control.fill
            border.color: Theme.control.border
            border.width: 1

            Text {
              id: buttonLabel
              anchors.centerIn: parent
              text: parent.modelData.text
              textFormat: Text.PlainText
              color: Theme.notification.text
              font.family: Style.font.family
              font.pixelSize: Style.font.small
            }

            MouseArea {
              id: buttonMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: parent.modelData.invoke()
            }
          }
        }
      }
    }
  }

  // A solid edge says which way it came from, and takes the urgent colour when it matters.
  Rectangle {
    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
    width: Style.space(3)
    color: root.critical ? Theme.urgent : Theme.notification.text
  }
}
