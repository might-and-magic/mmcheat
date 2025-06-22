local M = {}

function M.read(filename)
	local config = {}
	local current_section = "default" -- Default section for non-sectioned entries
	config[current_section] = {}   -- Initialize default section

	for line in io.lines(filename) do
		line = line:match("^%s*(.-)%s*$") -- Trim whitespace
		if line == "" or line:sub(1, 1) == ";" or line:sub(1, 1) == "#" then
			-- Skip empty lines and comments
		elseif line:sub(1, 1) == "[" then
			current_section = line:sub(2, -2) -- Get section name
			config[current_section] = config[current_section] or {}
		else
			-- Remove inline comments
			line = line:match("^(.-)%s*[;#].*$") or line
			local key, value = line:match("^(.-)=(.*)$")
			if key and value then
				key = key:match("^%s*(.-)%s*$") -- Trim key
				value = value:match("^%s*(.-)%s*$") -- Trim value

				-- Handle quoted values
				if value:match('^".*"$') or value:match("^'.*'$") then
					value = value:sub(2, -2)
				end

				config[current_section][key] = value
			end
		end
	end

	-- If default section is empty, remove it
	if next(config.default) == nil then
		config.default = nil
	end

	return config
end

-- Recursively (deep) merge two tables, t2 is incoming table that is merged into t1
local function deep_merge(t1, t2)
	for k, v in pairs(t2) do
		if type(v) == "table" and type(t1[k]) == "table" then
			deep_merge(t1[k], v) -- Recursively merge tables
		else
			t1[k] = v   -- Overwrite or add new value
		end
	end
end

local function format_ini_value(v)
	local str = tostring(v)
	if str:match('[%s;"#]') then
		str = str:gsub('"', '\\"') -- escape quotes
		str = '"' .. str .. '"'
	end
	return str
end

-- merge_mode: 0: overwrite, no merge (completely remove the whole existing config and write the new), 1: shallow merge (the whole section, if exists in the new config, will be replaced, if not, the old one will stay), 2: deep merge (the whole section, if exists in the new config, will be merged with the existing config)
function M.write(filename, config, merge_mode)
	local final_config = config

	-- If shouldMerge is true, deep merge with existing config
	if merge_mode ~= 0 and M.file_exists(filename) then
		local existing_config = M.read(filename)
		for section, keys in pairs(config) do
			if merge_mode == 1 then
				existing_config[section] = keys
			elseif merge_mode == 2 then
				if type(existing_config[section]) ~= "table" then
					existing_config[section] = {}
				end
				deep_merge(existing_config[section], keys)
			end
		end
		final_config = existing_config
	end

	local file = io.open(filename, "w")

	if not file then
		return
	end

	-- Write sections in the order they appear in config
	for section, keys in pairs(final_config) do
		if section ~= "default" then
			file:write("[" .. section .. "]\n")

			-- Sort all keys
			local ordered_keys = {}
			for key, value in pairs(keys) do
				ordered_keys[#ordered_keys + 1] = {
					key = key,
					value = value
				}
			end
			table.sort(ordered_keys, function(a, b)
				return a.key < b.key
			end)

			for _, key_data in ipairs(ordered_keys) do
				file:write(key_data.key .. "=" .. format_ini_value(key_data.value) .. "\n")
			end

			file:write("\n") -- Add a newline after each section
		end
	end

	file:close()
end

function M.file_exists(path)
	local file = io.open(path, "r") -- Try to open the file in read mode
	if file then
		file:close()             -- Close the file if it exists
		return true
	else
		return false -- File does not exist
	end
end

return M
