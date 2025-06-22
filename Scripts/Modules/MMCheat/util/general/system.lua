local ffi = require("ffi")
local iup = require("iup")
local i18n = require("MMCheat/i18n/i18n")

ffi.cdef [[
    unsigned long GetCurrentProcessId(void);
]]

local M = {}

-- Stop other processes with the same name
-- Returns true if any other process was stopped
function M.stop_other_processes(process_name)
	if not process_name then
		return false
	end

	local kernel32 = ffi.load("kernel32")
	local current_pid = kernel32.GetCurrentProcessId()

	local exe_name = process_name
	if not exe_name:match("%.exe$") then
		exe_name = exe_name .. ".exe"
	end

	local cmd = string.format('tasklist /FI "IMAGENAME eq %s" /FO CSV /NH', exe_name)
	local handle = io.popen(cmd)

	if not handle then
		return false
	end

	local pattern = string.format('"%s","(%%d+)"', exe_name:gsub("%.", "%%."))
	local found_any = false

	for line in handle:lines() do
		local pid = line:match(pattern)
		if pid then
			pid = tonumber(pid)
			if pid and pid ~= current_pid then
				os.execute(string.format("taskkill /F /PID %d", pid))
				found_any = true
			end
		end
	end

	handle:close()
	return found_any
end

-- Function to write to the file (overwrite or create new)
function M.save_text_file(path, content)
	local file, err = io.open(path, "w") -- "w" mode overwrites or creates new
	if not file then
		iup.Message(i18n._("warning"), i18n._("failed_to_write_file") .. i18n._("colon") .. err .. i18n._("right_paren"))
		return
	end
	file:write(content)
	file:close()
end

return M
