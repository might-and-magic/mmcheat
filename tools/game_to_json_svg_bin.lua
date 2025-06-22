local bit = require("bit")

local function json_decode(str)
	if type(str) ~= "string" then
		error("Input must be a string")
	end

	local pos = 1
	local len = #str

	local function skip_whitespace()
		while pos <= len and str:sub(pos, pos):match("%s") do
			pos = pos + 1
		end
	end

	local function parse_string()
		if str:sub(pos, pos) ~= '"' then
			error("Expected string at position " .. pos)
		end
		pos = pos + 1
		local result = ""
		while pos <= len do
			local char = str:sub(pos, pos)
			if char == '"' then
				pos = pos + 1
				return result
			elseif char == "\\" then
				pos = pos + 1
				if pos > len then
					error("Unexpected end of string at position " .. pos)
				end
				local next_char = str:sub(pos, pos)
				if next_char == "n" then
					result = result .. "\n"
				elseif next_char == "r" then
					result = result .. "\r"
				elseif next_char == "t" then
					result = result .. "\t"
				elseif next_char == "b" then
					result = result .. "\b"
				elseif next_char == "f" then
					result = result .. "\f"
				elseif next_char == '"' or next_char == "\\" then
					result = result .. next_char
				else
					error("Invalid escape sequence at position " .. pos)
				end
			else
				result = result .. char
			end
			pos = pos + 1
		end
		error("Unterminated string at position " .. pos)
	end

	local function parse_number()
		local start_pos = pos
		if str:sub(pos, pos) == "-" then
			pos = pos + 1
		end
		while pos <= len and str:sub(pos, pos):match("%d") do
			pos = pos + 1
		end
		if str:sub(pos, pos) == "." then
			pos = pos + 1
			while pos <= len and str:sub(pos, pos):match("%d") do
				pos = pos + 1
			end
		end
		if str:sub(pos, pos):match("[eE]") then
			pos = pos + 1
			if str:sub(pos, pos):match("[+-]") then
				pos = pos + 1
			end
			while pos <= len and str:sub(pos, pos):match("%d") do
				pos = pos + 1
			end
		end
		local num_str = str:sub(start_pos, pos - 1)
		local num = tonumber(num_str)
		if not num then
			error("Invalid number at position " .. start_pos)
		end
		return num
	end

	local function parse_value()
		skip_whitespace()
		if pos > len then
			error("Unexpected end of input at position " .. pos)
		end

		local char = str:sub(pos, pos)

		if char == '"' then
			return parse_string()
		elseif char == "{" then
			-- Parse object
			pos = pos + 1
			local result = {}
			skip_whitespace()
			if str:sub(pos, pos) == "}" then
				pos = pos + 1
				return result
			end
			while true do
				skip_whitespace()
				if str:sub(pos, pos) ~= '"' then
					error("Expected key at position " .. pos)
				end
				local key = parse_string()
				skip_whitespace()
				if str:sub(pos, pos) ~= ":" then
					error("Expected ':' at position " .. pos)
				end
				pos = pos + 1
				result[key] = parse_value()
				skip_whitespace()
				if str:sub(pos, pos) == "}" then
					pos = pos + 1
					return result
				elseif str:sub(pos, pos) == "," then
					pos = pos + 1
				else
					error("Expected ',' or '}' at position " .. pos)
				end
			end
		elseif char == "[" then
			-- Parse array
			pos = pos + 1
			local result = {}
			skip_whitespace()
			if str:sub(pos, pos) == "]" then
				pos = pos + 1
				return result
			end
			while true do
				table.insert(result, parse_value())
				skip_whitespace()
				if str:sub(pos, pos) == "]" then
					pos = pos + 1
					return result
				elseif str:sub(pos, pos) == "," then
					pos = pos + 1
				else
					error("Expected ',' or ']' at position " .. pos)
				end
			end
		elseif char == "t" then
			if str:sub(pos, pos + 3) == "true" then
				pos = pos + 4
				return true
			else
				error("Expected 'true' at position " .. pos)
			end
		elseif char == "f" then
			if str:sub(pos, pos + 4) == "false" then
				pos = pos + 5
				return false
			else
				error("Expected 'false' at position " .. pos)
			end
		elseif char == "n" then
			if str:sub(pos, pos + 3) == "null" then
				pos = pos + 4
				return nil
			else
				error("Expected 'null' at position " .. pos)
			end
		elseif char:match("[%-%d]") then
			return parse_number()
		else
			error("Unexpected character at position " .. pos)
		end
	end

	local result = parse_value()
	skip_whitespace()
	if pos <= len then
		error("Unexpected content after JSON at position " .. pos)
	end
	return result
end

local function json_encode(value)
	local function encode_value(val)
		local val_type = type(val)

		if val_type == "nil" then
			return "null"
		elseif val_type == "boolean" then
			return val and "true" or "false"
		elseif val_type == "number" then
			if val ~= val then -- NaN
				return "null"
			elseif val == math.huge then
				return "null"
			elseif val == -math.huge then
				return "null"
			else
				return tostring(val)
			end
		elseif val_type == "string" then
			-- Escape special characters
			local escaped = val:gsub("\\", "\\\\")
				:gsub('"', '\\"')
				:gsub("\n", "\\n")
				:gsub("\r", "\\r")
				:gsub("\t", "\\t")
				:gsub("\b", "\\b")
				:gsub("\f", "\\f")
			return '"' .. escaped .. '"'
		elseif val_type == "table" then
			-- Check if it's an array (sequential numeric keys starting from 1)
			local is_array = true
			local max_index = 0
			for k, _ in pairs(val) do
				if type(k) ~= "number" or k < 1 or k ~= math.floor(k) then
					is_array = false
					break
				end
				max_index = math.max(max_index, k)
			end

			if is_array and max_index == #val then
				-- Encode as array
				local parts = {}
				for i = 1, #val do
					table.insert(parts, encode_value(val[i]))
				end
				return "[" .. table.concat(parts, ",") .. "]"
			else
				-- Encode as object
				local parts = {}
				for k, v in pairs(val) do
					if type(k) == "string" then
						table.insert(parts, '"' .. k .. '":' .. encode_value(v))
					end
				end
				return "{" .. table.concat(parts, ",") .. "}"
			end
		else
			error("Cannot encode value of type: " .. val_type)
		end
	end

	return encode_value(value)
end

local function extract_map_data()
	local lines = {}
	local min_x, max_x = math.huge, -math.huge
	local min_y, max_y = math.huge, -math.huge

	for i, edge in Map.Outlines.Items do
		local v1 = Map.Vertexes[edge.Vertex1]
		local v2 = Map.Vertexes[edge.Vertex2]

		local x1, y1 = v1.X, -v1.Y
		local x2, y2 = v2.X, -v2.Y

		-- Validate i16 range
		if x1 < -32768 or x1 > 32767 or y1 < -32768 or y1 > 32767 or x2 < -32768 or x2 > 32767 or y2 < -32768 or y2 >
			32767 then
			error(string.format("Coordinate out of i16 range: (%d,%d) to (%d,%d)", x1, y1, x2, y2))
		end

		table.insert(lines, {
			x1 = x1,
			y1 = y1,
			x2 = x2,
			y2 = y2
		})

		-- Track bounding box
		min_x = math.min(min_x, x1, x2)
		max_x = math.max(max_x, x1, x2)
		min_y = math.min(min_y, y1, y2)
		max_y = math.max(max_y, y1, y2)
	end

	-- Validate bounding box range
	if min_x < -32768 or min_x > 32767 or min_y < -32768 or min_y > 32767 or max_x < -32768 or max_x > 32767 or max_y < -32768 or
		max_y > 32767 then
		error(string.format("Bounding box out of i16 range: (%d,%d) to (%d,%d)", min_x, min_y, max_x, max_y))
	end

	local map_name = Map.Name:match("(.+)%..+"):lower()

	return {
		min_x = min_x,
		min_y = min_y,
		max_x = max_x,
		max_y = max_y,
		lines = lines
	}, map_name
end

local function save_map_data_to_json(json_file_path, map_name, map_data)
	-- Load existing data or create new object
	local existing_data = {}
	local file = io.open(json_file_path, "r")
	if file then
		local content = file:read("*all")
		file:close()
		if content and content ~= "" then
			local success, data = pcall(json_decode, content)
			if success then
				---@diagnostic disable-next-line: cast-local-type
				existing_data = data
			end
		end
	end

	-- Merge new data
	existing_data[map_name] = map_data

	-- Write back to file
	local write_file = io.open(json_file_path, "w")
	if not write_file then
		error("Cannot open file for writing: " .. json_file_path)
	end

	local json_content = json_encode(existing_data)
	write_file:write(json_content)
	write_file:close()
end

local function save_map_data_to_svg(map_data, stroke_width, max_size, padding)
	local _stroke_width = stroke_width or 10
	local _max_size = max_size or 1024
	local _padding = padding or 100

	local min_x = map_data.min_x
	local min_y = map_data.min_y
	local max_x = map_data.max_x
	local max_y = map_data.max_y
	local lines = map_data.lines

	min_x = min_x - _padding
	max_x = max_x + _padding
	min_y = min_y - _padding
	max_y = max_y + _padding

	local width, height
	local _width = max_x - min_x
	local _height = max_y - min_y

	if _max_size <= 0 then
		width = _width
		height = _height
	else
		if _width > _height then
			width = max_size
			height = max_size * (_height / _width)
		else
			width = max_size * (_width / _height)
			height = max_size
		end
	end
	local svg = '<?xml version="1.0" encoding="UTF-8"?>\n'
	svg = svg ..
		string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%d %d %d %d">\n',
			width, height, min_x, min_y, max_x - min_x, max_y - min_y)
	svg = svg .. '<g stroke="black" stroke-width="' .. _stroke_width .. '" fill="none" stroke-linecap="round">\n'

	for _, line in ipairs(lines) do
		svg = svg .. string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" />\n', line.x1, line.y1, line.x2, line.y2)
	end

	svg = svg .. '</g>\n'
	svg = svg .. '</svg>\n'

	return svg
end

local function json2bin(json_file_path, bin_file_path, sort_fn)
	local json_file = io.open(json_file_path, "r")
	if not json_file then
		error("Cannot open JSON file: " .. json_file_path)
	end

	local json_content = json_file:read("*all")
	json_file:close()

	local data = json_decode(json_content)
	if not data then
		error("Failed to decode JSON from: " .. json_file_path)
	end

	local bin_file = io.open(bin_file_path, "wb")
	if not bin_file then
		error("Cannot create binary file: " .. bin_file_path)
	end

	-- Get sorted map names if sort_fn is provided
	local map_names = {}
	---@diagnostic disable-next-line: param-type-mismatch
	for map_name, _ in pairs(data) do
		table.insert(map_names, map_name)
	end

	if sort_fn then
		table.sort(map_names, sort_fn)
	end

	-- Calculate header size and data offsets
	local header_size = 2 -- Start with 2 bytes for map count
	local data_offset = 0
	local map_entries = {}

	-- First pass: calculate sizes (use sorted order if sort_fn provided)
	for _, map_name in ipairs(map_names) do
		local map_data = data[map_name]
		local name_bytes = map_name:len()
		local entry_size = 1 + name_bytes + 4 + 4 -- u8 + char[] + u32 + u32
		header_size = header_size + entry_size

		local data_size = 2 + 2 + 2 + 2         -- i16 * 4 for bounds
		data_size = data_size + (#map_data.lines * 8) -- i16 * 4 for each line

		map_entries[map_name] = {
			name_bytes = name_bytes,
			data_offset = data_offset,
			data_size = data_size,
			map_data = map_data
		}

		data_offset = data_offset + data_size
	end

	-- Write map count (u16, little endian)
	local map_count = #map_names
	bin_file:write(string.char(
		bit.band(map_count, 0xFF),
		bit.band(bit.rshift(map_count, 8), 0xFF)
	))

	-- Write header (use sorted order if sort_fn provided)
	for _, map_name in ipairs(map_names) do
		local entry = map_entries[map_name]
		-- Write string length (u8)
		bin_file:write(string.char(entry.name_bytes))
		-- Write map name (char[])
		bin_file:write(map_name)
		-- Write data offset (u32, little endian) - offset is relative to start of file
		local offset = header_size + entry.data_offset
		bin_file:write(string.char(
			bit.band(offset, 0xFF),
			bit.band(bit.rshift(offset, 8), 0xFF),
			bit.band(bit.rshift(offset, 16), 0xFF),
			bit.band(bit.rshift(offset, 24), 0xFF)
		))
		-- Write data length (u32, little endian)
		local length = entry.data_size
		bin_file:write(string.char(
			bit.band(length, 0xFF),
			bit.band(bit.rshift(length, 8), 0xFF),
			bit.band(bit.rshift(length, 16), 0xFF),
			bit.band(bit.rshift(length, 24), 0xFF)
		))
	end

	-- Write data (use sorted order if sort_fn provided)
	for _, map_name in ipairs(map_names) do
		local entry = map_entries[map_name]
		local map_data = entry.map_data

		-- Write bounds (i16, little endian)
		local function write_i16(value)
			if value < 0 then
				value = value + 65536 -- Convert to unsigned
			end
			bin_file:write(string.char(
				bit.band(value, 0xFF),
				bit.band(bit.rshift(value, 8), 0xFF)
			))
		end

		write_i16(map_data.min_x)
		write_i16(map_data.min_y)
		write_i16(map_data.max_x)
		write_i16(map_data.max_y)

		-- Write lines
		for _, line in ipairs(map_data.lines) do
			write_i16(line.x1)
			write_i16(line.y1)
			write_i16(line.x2)
			write_i16(line.y2)
		end
	end

	bin_file:close()
end

---@diagnostic disable-next-line: duplicate-set-field
function events.KeyDown(t)
	if t.Key == const.Keys.F then
		local found = false
		for i = 1, Game.MapStats.Count - 1 do
			local map = Game.MapStats[i]
			if map.FileName:lower() == Map.Name:lower() then
				found = true
				goto cont
			end
			if found and (t.Key == const.Keys.F or map.FileName:match(".+%.(.+)"):lower() == "blv") then
				evt.MoveToMap({
					Name = map.FileName
				})
				return
			end
			::cont::
			if i == Game.MapStats.Count - 1 then
				Game.ShowStatusText("End of all maps")
				return
			end
		end
	end
	if t.Key == const.Keys.D then
		local map_data, map_name = extract_map_data()
		save_map_data_to_json("indoor2dmap.json", map_name, map_data)
		Game.ShowStatusText("Saved to indoor2dmap.json")
	end
	if t.Key == const.Keys.G then
		local map_data = extract_map_data()
		local svg = save_map_data_to_svg(map_data)
		local f = io.open("indoor2dmap.svg", "w")
		if f then
			f:write(svg)
			f:close()
			Game.ShowStatusText("Saved to indoor2dmap.svg")
		else
			Game.ShowStatusText("Cannot open file for writing: indoor2dmap.svg")
		end
	end
	if t.Key == const.Keys.T then
		local function get_map_index(file_name_without_ext)
			for i = 1, Game.MapStats.Count - 1 do
				local map = Game.MapStats[i]
				local map_name_without_ext = map.FileName:match("(.+)%..+")
				if map_name_without_ext and map_name_without_ext:lower() == file_name_without_ext:lower() then
					return i
				end
			end
			return nil
		end
		local function sort_fn(a, b)
			return get_map_index(a) < get_map_index(b)
		end
		json2bin("indoor2dmap.json", "indoor2dmap.bin", sort_fn)
		Game.ShowStatusText("indoor2dmap.json converted to indoor2dmap.bin")
	end
end
