#!/usr/bin/env python3
"""Scope herdr's Agents panel to the selected space, and jump to agents that
need attention.

Usage: space_scope.py sync|current|focus|all|toggle|cycle|attention

Panel modes:
  current  only agents in the selected space
  focus    the selected space, plus blocked/done agents in every other space
  all      every agent (herdr's default panel)

"toggle" flips current <-> all, "cycle" steps current -> focus -> all.
The mode is saved in HERDR_PLUGIN_STATE_DIR so it survives server restarts;
"sync" re-applies it.

"attention" focuses the next agent that is blocked (waiting on you) or done
(finished, not yet looked at), blocked first and longest-waiting first, across
all spaces whatever the panel mode. Pressing it again moves to the next one.
"""
import json
import os
import socket
import sys
from pathlib import Path

SOURCE = "space-scoped-agents"
SOCKET = os.environ.get("HERDR_SOCKET_PATH") or os.path.expanduser("~/.config/herdr/herdr.sock")
STATE = Path(os.environ.get("HERDR_PLUGIN_STATE_DIR") or os.path.expanduser("~/.local/state/herdr-space-scope")) / "mode"

MODES = ("current", "focus", "all")

CURRENT_SPACE = {"op": "eq", "field": "workspace_id", "value": {"context": "current_workspace_id"}}
NEEDS_ATTENTION = {"op": "in", "field": "status", "values": ["blocked", "done"]}


def request(method, params):
    with socket.socket(socket.AF_UNIX) as s:
        s.connect(SOCKET)
        s.sendall((json.dumps({"id": "1", "method": method, "params": params}) + "\n").encode())
        buf = b""
        while not buf.endswith(b"\n"):
            chunk = s.recv(65536)
            if not chunk:
                break
            buf += chunk
    reply = json.loads(buf or b"{}")
    if "error" in reply:
        sys.exit(f"{method} failed: {reply['error']}")
    return reply


def read_mode():
    try:
        mode = STATE.read_text().strip()
    except OSError:
        mode = ""
    return mode if mode in MODES else "current"


def apply(mode):
    if mode == "current":
        request("agent.view.set", {"source": SOURCE, "label": "This space", "filter": CURRENT_SPACE})
    elif mode == "focus":
        # No sort: keep the panel grouped by space so indexed focus stays stable
        request("agent.view.set", {
            "source": SOURCE,
            "label": "This space + waiting",
            "filter": {"op": "any", "filters": [CURRENT_SPACE, NEEDS_ATTENTION]},
        })
    else:
        request("agent.view.clear", {"source": SOURCE})
    STATE.parent.mkdir(parents=True, exist_ok=True)
    STATE.write_text(mode + "\n")


def jump_to_attention():
    result = request("agent.list", {})["result"]
    agents = result.get("agents", result) if isinstance(result, dict) else result
    waiting = [a for a in agents if a.get("agent_status") in ("blocked", "done")]
    if not waiting:
        request("notification.show", {"title": "No agents need attention", "sound": "none"})
        return
    waiting.sort(key=lambda a: (a["agent_status"] != "blocked", a.get("state_change_seq") or 0))
    try:
        active = json.loads(os.environ.get("HERDR_PLUGIN_CONTEXT_JSON") or "{}").get("focused_pane_id")
    except ValueError:
        active = None
    active = active or os.environ.get("HERDR_PANE_ID")
    ids = [a["pane_id"] for a in waiting]
    target = ids[(ids.index(active) + 1) % len(ids)] if active in ids else ids[0]
    request("agent.focus", {"target": target})


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "sync"
    if cmd == "sync":
        apply(read_mode())
    elif cmd in MODES:
        apply(cmd)
    elif cmd == "toggle":
        apply("all" if read_mode() != "all" else "current")
    elif cmd == "cycle":
        apply(MODES[(MODES.index(read_mode()) + 1) % len(MODES)])
    elif cmd == "attention":
        jump_to_attention()
    else:
        sys.exit(__doc__)


if __name__ == "__main__":
    main()
