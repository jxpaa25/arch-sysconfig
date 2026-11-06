//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_DEFAULT_TEXT_RENDER_TYPE=NativeTextRendering
import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Background
import qs.Bar
import qs.Menu

// The desktop shell, one long-running process. Each surface lives in its own directory
// and everything else talks to it over `qs ipc call <target> <function>`.
ShellRoot {
  Background {}
  Bar {}
  Menu {}

  IpcHandler {
    target: "shell"

    function ping(): string { return "pong" }
    function reloadTheme(): void { Theme.reload() }
    function toggleBar(): void { Saved.barHidden = !Saved.barHidden }
    function setBarHidden(hidden: bool): void { Saved.barHidden = hidden }
    function barHidden(): bool { return Saved.barHidden }
  }

  IpcHandler {
    target: "panels"

    function toggle(id: string): void { Panels.toggle(id) }
    function toggleAt(position: int): void { Panels.toggleAt(position) }
    function close(): void { Panels.close() }
  }
}
