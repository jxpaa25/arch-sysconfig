-- Small helpers shared by the rest of the config, as the global `desk`.

desk = {}

local home = os.getenv("HOME")

desk.home = home
desk.toggles_dir = home .. "/.local/state/desk/toggles"

function desk.read_line(path)
  local file = io.open(path, "r")
  if not file then
    return nil
  end
  local line = file:read("*l")
  file:close()
  return line
end

desk.hostname = desk.read_line("/etc/hostname") or ""

-- Like require(), but a missing file is fine. Errors inside the file still show.
function desk.require_optional(module)
  if package.searchpath(module, package.path) then
    return require(module)
  end
end

-- action is a dispatcher, a Lua function, or a string to run as a shell command.
function desk.bind(keys, description, action, options)
  local opts = options or {}
  opts.description = description
  if type(action) == "string" then
    action = hl.dsp.exec_cmd(action)
  end
  hl.bind(keys, action, opts)
end

-- Run an app in its own systemd unit, so uwsm can clean it up with the session.
function desk.launch(command)
  return "uwsm-app -- " .. command
end

-- match is a class pattern, or a table of match properties.
function desk.window(match, rules)
  rules.match = rules.match or {}
  if type(match) == "string" then
    rules.match.class = match
  else
    for key, value in pairs(match) do
      rules.match[key] = value
    end
  end
  hl.window_rule(rules)
end

function desk.transparent_window(match, opacity)
  desk.window(match, { opacity = opacity or "0.985 0.96" })
end
