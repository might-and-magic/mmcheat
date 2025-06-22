local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")
local bit = require("bit")
local modlist = require("MMCheat/data/index")

local bin_file_dir = "Scripts/Modules/MMCheat/data/"
local bin_file_main_name = "indoor2dmap.bin"

local bin_file_paths = {
	{
		mod_name = nil,
		path = bin_file_dir .. bin_file_main_name
	}
}
for _, mod_name in ipairs(modlist) do
	table.insert(bin_file_paths, {
		mod_name = mod_name,
		path = bin_file_dir .. mod_name .. "_" .. bin_file_main_name
	})
end

-- Read map header from binary file
local function read_map_header(bin_file_path, mod_name)
	local bin_file = io.open(bin_file_path, "rb")
	if not bin_file then
		print("Cannot open binary file: " .. bin_file_path)
		return nil
	end

	-- Read map count (u16, little endian)
	local count_bytes = bin_file:read(2)
	if not count_bytes or count_bytes:len() ~= 2 then
		print("Failed to read map count")
		bin_file:close()
		return nil
	end
	local map_count = string.byte(count_bytes, 1) + bit.lshift(string.byte(count_bytes, 2), 8)

	local header = {}

	-- Read exactly map_count entries
	for i = 1, map_count do
		-- Read string length (u8)
		local name_length_byte = bin_file:read(1)
		if not name_length_byte then
			print("Unexpected end of file while reading map " .. i)
			bin_file:close()
			return nil
		end

		local name_length = string.byte(name_length_byte)

		-- Read map name (char[])
		local map_name = bin_file:read(name_length)
		if not map_name or map_name:len() ~= name_length then
			print("Failed to read map name for map " .. i)
			bin_file:close()
			return nil
		end

		-- Read data offset (u32, little endian)
		local offset_bytes = bin_file:read(4)
		if not offset_bytes or offset_bytes:len() ~= 4 then
			print("Failed to read data offset for map " .. i)
			bin_file:close()
			return nil
		end
		local offset = string.byte(offset_bytes, 1) +
			bit.lshift(string.byte(offset_bytes, 2), 8) +
			bit.lshift(string.byte(offset_bytes, 3), 16) +
			bit.lshift(string.byte(offset_bytes, 4), 24)

		-- Read data length (u32, little endian)
		local length_bytes = bin_file:read(4)
		if not length_bytes or length_bytes:len() ~= 4 then
			print("Failed to read data length for map " .. i)
			bin_file:close()
			return nil
		end
		local length = string.byte(length_bytes, 1) +
			bit.lshift(string.byte(length_bytes, 2), 8) +
			bit.lshift(string.byte(length_bytes, 3), 16) +
			bit.lshift(string.byte(length_bytes, 4), 24)

		header[map_name] = {
			offset = offset,
			length = length,
			mod_name = mod_name
		}
	end

	bin_file:close()
	return header
end

-- Load specific map data from binary file
local function load_map(header, bin_file_dir, bin_file_main_name, map_name, inverted_y_axis)
	if not header[map_name] then
		return nil
	end

	local mod_prefix = header[map_name].mod_name and header[map_name].mod_name .. "_" or ""
	local bin_file_path = bin_file_dir .. mod_prefix .. bin_file_main_name

	local bin_file = io.open(bin_file_path, "rb")
	if not bin_file then
		error("Cannot open binary file: " .. bin_file_path)
	end

	local map_info = header[map_name]

	-- Seek to map data
	bin_file:seek("set", map_info.offset)

	-- Read bounds (i16, little endian)
	local function read_i16()
		local bytes = bin_file:read(2)
		if not bytes or bytes:len() ~= 2 then
			error("Failed to read i16 value")
		end
		local value = string.byte(bytes, 1) + bit.lshift(string.byte(bytes, 2), 8)
		-- Convert to signed
		if value >= 32768 then
			value = value - 65536
		end
		return value
	end

	local min_x = read_i16()
	local min_y = read_i16()
	local max_x = read_i16()
	local max_y = read_i16()

	-- Calculate number of lines
	local remaining_bytes = map_info.length - 8 -- 4 i16 values for bounds
	local num_lines = remaining_bytes / 8    -- 4 i16 values per line

	local lines = {}
	for i = 1, num_lines do
		local x1 = read_i16()
		local y1 = inverted_y_axis and -read_i16() or read_i16()
		local x2 = read_i16()
		local y2 = inverted_y_axis and -read_i16() or read_i16()
		table.insert(lines, { x1 = x1, y1 = y1, x2 = x2, y2 = y2 })
	end

	bin_file:close()

	return {
		min_x = min_x,
		min_y = inverted_y_axis and -max_y or min_y,
		max_x = max_x,
		max_y = inverted_y_axis and -min_y or max_y,
		lines = lines
	}
end

local M = {
	header = {},
	data = {},
}

function M.init()
	M.header = {}
	for _, bin_file_path in ipairs(bin_file_paths) do
		M.header = utils.merge_tables(M.header, read_map_header(bin_file_path.path, bin_file_path.mod_name))
	end
end

function M.cleanup()
	M.header = {}
	M.data = {}
end

states.register_cleanup(M.cleanup)

function M.get_map(map_name, without_cache)
	local _map_name = utils.normalize_map_filename(map_name)
	-- map names are already all lowercase in indoor2dmap.bin
	if #M.header == 0 then
		M.init()
	end
	if M.data[_map_name] then
		return M.data[_map_name]
	end
	local map = load_map(M.header, bin_file_dir, bin_file_main_name, _map_name, true)
	if not without_cache then
		M.data[_map_name] = map
	end
	return map
	-- {
	-- 	min_x = min_x,
	-- 	min_y = min_y,
	-- 	max_x = max_x,
	-- 	max_y = max_y,
	-- 	lines = lines ({x1 = x1, y1 = y1, x2 = x2, y2 = y2})
	-- }
end

-- stroke_width (number, optional): Thickness of the SVG lines (default is 10)
-- max_nominal_size (number, optional): Fixed nominal max(width, height) of the SVG output. If nil, it uses default number 1024. If <= 0, it uses coordinate width and height
-- padding (number, optional): padding to add to the border. Use game coordinate system's unit (default is 100)
-- without_cache: (boolean, optional): if true, directly get data from the binary file (but if already cached, get it from the cache) without caching it afterwards
-- All outlines are included, both visible and invisible
function M.get_map_svg(map_name, stroke_width, max_nominal_size, padding, without_cache)
	local _stroke_width = stroke_width or 10
	local _max_nominal_size = max_nominal_size or 1024
	local _padding = padding or 100

	local map = M.get_map(map_name, without_cache)
	if not map then
		return nil
	end

	-- For SVG, we need to flip the Y-axis (SVG Y increases downward)
	local min_x = map.min_x
	local min_y = -map.max_y -- Flip Y
	local max_x = map.max_x
	local max_y = -map.min_y -- Flip Y
	local lines = map.lines

	min_x = min_x - _padding
	max_x = max_x + _padding
	min_y = min_y - _padding
	max_y = max_y + _padding

	local width, height
	local _width = max_x - min_x
	local _height = max_y - min_y
	if _max_nominal_size <= 0 then
		width = _width
		height = _height
	else
		if _width > _height then
			width = _max_nominal_size
			height = _max_nominal_size * (_height / _width)
		else
			width = _max_nominal_size * (_width / _height)
			height = _max_nominal_size
		end
	end

	local svg = '<?xml version="1.0" encoding="UTF-8"?>\n'
	svg = svg ..
		string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="%d %d %d %d">\n',
			width, height, min_x, min_y, max_x - min_x, max_y - min_y)
	svg = svg .. '<g stroke="black" stroke-width="' .. _stroke_width .. '" fill="none" stroke-linecap="round">\n'

	for _, line in ipairs(lines) do
		-- Flip Y coordinates
		svg = svg .. string.format('<line x1="%d" y1="%d" x2="%d" y2="%d" />\n',
			line.x1, -line.y1, line.x2, -line.y2)
	end

	svg = svg .. '</g>\n'
	svg = svg .. '</svg>\n'

	return svg
end

return M

--[[
binary:
```
header:
{
  u16 (map count)
  u8 (map_name string length in bytes)
  char[] (map_name)
  u32 (map data offset relative to the start of the file)
  u32 (map data length in bytes)
} (each map) []

no empty bytes between header and data

data:
{
  i16 (min_x)
  i16 (min_y)
  i16 (max_x)
  i16 (max_y)
  {
    i16 (x1)
    i16 (y1)
    i16 (x2)
    i16 (y2)
  } (each line) []
} (each map) []
```

json:
```
{
  <map_name>: {
    "min_x": <min_x>,
    "min_y": <min_y>,
    "max_x": <max_x>,
    "max_y": <max_y>,
    "lines": [
      [<x1>, <y1>, <x2>, <y2>],
      ...
    ]
  }
}
```
json example:
```
{
  "d35": {
    "min_x": -5904,
    "min_y": -5552,
    "max_x": 5616,
    "max_y": 5552,
    "lines": [
      [-4032, 4320, -3744, 4320],
      [-4032, 4608, -3456, 4608]
    ]
  }
}
```

The coordinate system in indoor2dmap.bin and in the game indoor map blv files is of top-left corner origin
which is different from the common coordinate system in the game
therefore y-axis should be inverted for the data to be used
meanwhile, SVG is also of top-left corner origin, if converted from indoor2dmap.bin data, y-axis should be inverted back
]]
