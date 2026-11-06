import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "MenuData.js" as Data

// The launcher and every menu, plus a picker that scripts can call through menu-pick.
Scope {
  id: root

  property bool opened: false
  property string menuId: "root"
  property var stack: []
  // Row conditions from `when` and `checked`. Hidden until the answer arrives.
  property var hiddenRows: ({})
  property var checkedRows: ({})

  // Picker mode: { prompt, rows, result }, set by a script through IPC.
  property var pick: null

  readonly property var apps: {
    var values = DesktopEntries.applications.values.filter(function(entry) {
      return !entry.noDisplay
    })
    return values.map(function(entry) {
      return {
        label: entry.name,
        image: Quickshell.iconPath(entry.icon, true) || "",
        icon: Quickshell.iconPath(entry.icon, true) ? "" : "\u{F003B}",
        search: [entry.genericName, entry.comment].concat(entry.keywords || []),
        app: entry.id
      }
    }).sort(function(a, b) { return a.label.toLowerCase() < b.label.toLowerCase() ? -1 : 1 })
  }

  function rowsOf(id) {
    if (id === "apps") return apps
    var menu = Data.menus[id]
    return menu ? menu.rows : []
  }

  function decorate(row, id) {
    var key = id + "/" + row.label
    if (hiddenRows[key]) return null
    var out = Object.assign({}, row)
    if (row.menu) out.more = true
    if (checkedRows[key]) out.checked = true
    return out
  }

  readonly property var visibleRows: {
    var query = card.filter
    if (pick) return query ? Data.ranked(pick.rows, query) : pick.rows

    var id = menuId
    if (!query) {
      return rowsOf(id).map(function(row) { return root.decorate(row, id) }).filter(Boolean)
    }
    if (id === "root") {
      // Search everything. Apps come first when the match is equally good.
      var all = apps.concat(Data.flatten().map(function(row) {
        return root.decorate(row, row.sourceMenu)
      }).filter(Boolean))
      return Data.ranked(all, query).slice(0, 40)
    }
    return Data.ranked(rowsOf(id).map(function(row) { return root.decorate(row, id) }).filter(Boolean), query)
  }

  function evaluate(id) {
    var lines = []
    var rows = id === "root" ? [] : rowsOf(id)
    if (id === "root") {
      for (var m in Data.menus) rows = rows.concat(Data.menus[m].rows.map(function(row) {
        return Object.assign({ owner: m }, row)
      }))
    }
    rows.forEach(function(row) {
      var key = (row.owner || id) + "/" + row.label
      if (row.when) lines.push("(" + row.when + ") >/dev/null 2>&1 || echo " + Run.quote("H" + key))
      if (row.checked) lines.push("(" + row.checked + ") >/dev/null 2>&1 && echo " + Run.quote("C" + key))
    })
    guards.running = false
    if (!lines.length) {
      hiddenRows = ({})
      checkedRows = ({})
      return
    }
    guards.command = ["bash", "-c", lines.join("\n") + "\ntrue"]
    guards.running = true
  }

  Process {
    id: guards
    stdout: StdioCollector {
      onStreamFinished: {
        var hidden = {}
        var checked = {}
        text.split("\n").forEach(function(line) {
          if (line.charAt(0) === "H") hidden[line.substring(1)] = true
          if (line.charAt(0) === "C") checked[line.substring(1)] = true
        })
        root.hiddenRows = hidden
        root.checkedRows = checked
      }
    }
  }

  function open(id) {
    finishPick("")
    menuId = id && (Data.menus[id] || id === "apps") ? id : "root"
    stack = []
    evaluate(menuId)
    opened = true
    card.reset()
  }

  function close() {
    opened = false
    finishPick("")
  }

  function toggle(id) {
    if (opened && !pick && menuId === (id || "root")) close()
    else open(id)
  }

  function enter(id) {
    stack = stack.concat([menuId])
    menuId = id
    evaluate(id)
    card.reset()
  }

  function goBack() {
    if (!stack.length) return
    menuId = stack[stack.length - 1]
    stack = stack.slice(0, -1)
    evaluate(menuId)
    card.reset()
  }

  function activate(row) {
    if (pick) {
      var value = row.value
      opened = false
      finishPick(value)
      return
    }
    if (row.menu) {
      enter(row.menu)
      return
    }
    close()
    if (row.app) Quickshell.execDetached(["uwsm-app", "--", row.app + ".desktop"])
    else if (row.action) Run.sh(row.action)
  }

  // A script's question gets exactly one answer, even an empty one.
  function finishPick(value) {
    if (!pick) return
    var result = pick.result
    pick = null
    Quickshell.execDetached(["bash", "-c", 'printf "%s\\n" "$1" > "$2"', "--", value, result])
  }

  // Options are lines of "label" or "label<TAB>hint". The whole line comes back.
  function startPick(prompt, options, result) {
    finishPick("")
    pick = {
      prompt: prompt,
      result: result,
      rows: options.split("\n").filter(Boolean).map(function(line) {
        var parts = line.split("\t")
        return { label: parts[0], hint: parts[1] || "", value: line }
      })
    }
    opened = true
    card.reset()
  }

  Process {
    id: optionsReader
    property string prompt: ""
    property string result: ""
    stdout: StdioCollector {
      onStreamFinished: root.startPick(optionsReader.prompt, text, optionsReader.result)
    }
  }

  // The themes that exist, as rows that switch to them.
  Process {
    id: themesReader
    command: ["bash", "-c", "ls -1 \"$HOME/.local/share/desk/themes\"; readlink \"$HOME/.local/state/theme/current\""]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = text.split("\n").filter(Boolean)
        var names = lines.slice(0, -1)
        Data.menus.theme.rows = names.map(function(name) {
          return {
            label: name.charAt(0).toUpperCase() + name.slice(1),
            action: "theme-set " + name,
            checked: "[[ $(basename \"$(readlink ~/.local/state/theme/current)\") == " + name + " ]]"
          }
        })
      }
    }
  }

  Overlay {
    id: overlay
    shown: root.opened
    scrim: Theme.menu.scrim
    WlrLayershell.namespace: "desk-menu"
    onDismissed: root.close()

    ListCard {
      id: card
      anchors.horizontalCenter: parent.horizontalCenter
      rows: root.visibleRows
      canGoBack: root.stack.length > 0
      placeholder: root.pick ? root.pick.prompt : (root.menuId === "apps" ? "Apps" : Data.menus[root.menuId].title)
      onActivated: function(row) { root.activate(row) }
      onBack: root.goBack()
      onCancelled: root.close()
    }
  }

  IpcHandler {
    target: "menu"

    function toggle(id: string): void { root.toggle(id) }
    function close(): void { root.close() }
    function pick(prompt: string, optionsFile: string, resultFile: string): void {
      optionsReader.prompt = prompt
      optionsReader.result = resultFile
      optionsReader.command = ["cat", optionsFile]
      optionsReader.running = true
    }
  }
}
