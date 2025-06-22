local ini = require("MMCheat/util/general/ini")

local settings = {}

local M = {}

M.conf_path = "Scripts/Modules/MMCheat/conf.ini"

function M.init()
	settings = {}
	if ini.file_exists(M.conf_path) then
		local ini_settings_section = ini.read(M.conf_path).settings
		if ini_settings_section then
			settings = ini_settings_section
		end
	end
end

-- Note: the value is always a string!
function M.get_setting(key)
	return settings[key]
end

function M.set_setting(key, value)
	local str_value = tostring(value)
	if settings[key] ~= str_value then
		settings[key] = str_value
		ini.write(M.conf_path, {
			settings = settings
		}, 2)
	end
end

return M
