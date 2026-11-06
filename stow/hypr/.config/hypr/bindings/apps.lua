-- Apps. Open new terminals in the directory of the focused terminal.
desk.bind("SUPER + RETURN", "Terminal", function()
  local window = hl.get_active_window()
  if window and window.pid then
    hl.exec_cmd("launch-terminal --pid=" .. window.pid)
  else
    hl.exec_cmd("launch-terminal")
  end
end)

desk.bind("SUPER + SHIFT + RETURN", "Browser", "launch-browser")
desk.bind("SUPER + SHIFT + B", "Browser", "launch-browser")
desk.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "launch-browser --private")
desk.bind("SUPER + SHIFT + N", "Editor", "launch-tui helix")
desk.bind("SUPER + SHIFT + F", "File manager", "launch-tui spf")
desk.bind("SUPER + SHIFT + ALT + F", "File manager (cwd)", function()
  hl.exec_cmd('launch-tui spf "$(terminal-cwd)"')
end)
desk.bind("SUPER + ALT + RETURN", "Tmux", 'launch-terminal bash -c "tmux attach || tmux new -s Work"')
desk.bind("SUPER + CTRL + RETURN", "Herdr", "launch-terminal herdr")
desk.bind("SUPER + SHIFT + T", "Activity", "launch-tui btop")
desk.bind("SUPER + SHIFT + D", "Docker", "launch-tui lazydocker")

-- Capture.
desk.bind("PRINT", "Screenshot", "screenshot")
desk.bind("SUPER + CTRL + ALT + C", "Screenshot", "screenshot")
desk.bind("SUPER + PRINT", "Color picker", "pkill hyprpicker || hyprpicker -a")
