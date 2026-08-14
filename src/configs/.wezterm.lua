local wezterm = require 'wezterm'

local config = {}

if wezterm.config_builder then
  config = wezterm.config_builder()
end

-- config.color_scheme = 'Codeschool (light) (terminal.sexy)'
config.color_scheme = 'Tomorrow Night Blue (Gogh)'

config.font =
    wezterm.font('Maple Mono NF', { weight = 'DemiBold' })

config.font_size = 14.0

config.launch_menu = {
  {
    args = { 'top' },
  },
  { label = 'Nu Shell',   args = { '/usr/bin/nu' }, },
  { label = 'Fish Shell', args = { '/usr/bin/fish' }, },
}

return config
