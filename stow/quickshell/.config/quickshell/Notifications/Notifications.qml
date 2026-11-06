import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// The notification daemon: toasts at the top right of the focused monitor, plus a history
// and a keyboard list. While silenced, only critical notifications show. The rest go
// straight to the history.
Scope {
  id: root

  // Newest first. Plain records, so they outlive the notification they came from.
  property var history: []
  property string cardMode: ""

  readonly property var live: server.trackedNotifications.values
  readonly property int maxToasts: 5

  function record(notification) {
    var entry = {
      notification: notification,
      label: notification.summary || notification.appName,
      detail: notification.body.replace(/\s+/g, " "),
      hint: Qt.formatDateTime(new Date(), "HH:mm"),
      app: notification.appName
    }
    history = [entry].concat(history).slice(0, 100)
    return entry
  }

  function newest() {
    return live.length ? live[live.length - 1] : null
  }

  function hasDefaultAction(notification) {
    return notification.actions.some(function(action) { return action.identifier === "default" })
  }

  function act(notification) {
    var actions = notification.actions
    for (var i = 0; i < actions.length; i++) {
      if (actions[i].identifier === "default") {
        actions[i].invoke()
        return
      }
    }
    if (actions.length) actions[0].invoke()
    else notification.dismiss()
  }

  function dismissAll() {
    live.slice().forEach(function(notification) { notification.dismiss() })
  }

  NotificationServer {
    id: server
    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    bodyMarkupSupported: false
    imageSupported: true
    persistenceSupported: true
    bodyHyperlinksSupported: false

    onNotification: function(notification) {
      root.record(notification)
      if (Saved.doNotDisturb && notification.urgency !== NotificationUrgency.Critical) return
      notification.tracked = true
    }
  }

  // Sized to its toasts and otherwise absent, so it never blocks the desktop.
  PanelWindow {
    id: toasts

    screen: Panels.screenByName(Panels.focusedScreenName())
    visible: root.live.length > 0
    color: "transparent"
    exclusionMode: ExclusionMode.Normal
    anchors { top: true; right: true }
    margins { top: Style.edgeGap; right: Style.edgeGap }
    implicitWidth: Style.space(380)
    implicitHeight: Math.max(1, stack.implicitHeight)
    WlrLayershell.namespace: "desk-notifications"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    Column {
      id: stack
      width: parent.width
      spacing: Style.spacing.md

      Repeater {
        model: server.trackedNotifications

        Toast {
          required property var modelData
          required property int index

          notification: modelData
          width: stack.width
          // Oldest at the top of the model. Past the limit, the older ones wait their turn.
          visible: index >= root.live.length - root.maxToasts
          onActivated: root.act(modelData)
        }
      }
    }
  }

  // History, or the live notifications driven from the keyboard.
  Overlay {
    id: overlay

    shown: root.cardMode !== ""
    scrim: Theme.menu.scrim
    WlrLayershell.namespace: "desk-notification-list"
    onDismissed: root.cardMode = ""

    ListCard {
      id: card

      anchors.horizontalCenter: parent.horizontalCenter
      y: Math.max(Style.edgeGap, Math.round((overlay.height - height) / 2))
      placeholder: (root.cardMode === "history" ? "History" : "Notifications") + "…"
      rows: {
        var query = filter.toLowerCase()
        var source = root.history
        if (root.cardMode === "live") {
          source = source.filter(function(entry) {
            return entry.notification && entry.notification.tracked
          })
        }
        return source.filter(function(entry) {
          return !query || (entry.label + " " + entry.detail + " " + entry.app).toLowerCase().indexOf(query) !== -1
        })
      }

      onActivated: function(row) {
        root.cardMode = ""
        if (row.notification && row.notification.tracked) root.act(row.notification)
      }
      onDeleted: function(row) {
        if (row.notification && row.notification.tracked) row.notification.dismiss()
        root.history = root.history.filter(function(entry) { return entry !== row })
      }
      onCancelled: root.cardMode = ""
    }

    onShownChanged: if (shown) card.reset()
  }

  IpcHandler {
    target: "notifications"

    function dismissOrAct(): void {
      var notification = root.newest()
      if (!notification) return
      if (root.hasDefaultAction(notification)) root.act(notification)
      else notification.dismiss()
    }
    function dismissLast(): void {
      var notification = root.newest()
      if (notification) notification.dismiss()
    }
    function dismissAll(): void { root.dismissAll() }
    function keyboard(): void { root.cardMode = root.cardMode === "live" ? "" : "live" }
    function history(): void { root.cardMode = root.cardMode === "history" ? "" : "history" }
    function toggleSilence(): void { Saved.doNotDisturb = !Saved.doNotDisturb }
    function count(): int { return root.live.length }
  }
}
