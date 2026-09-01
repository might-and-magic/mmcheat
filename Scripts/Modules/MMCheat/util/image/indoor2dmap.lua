-- Indoor 2D map data provider.
-- Outline data is extracted at runtime from the game's own map files
-- (see util/image/blvreader.lua): the current map is read directly from
-- game memory, any other map is read from the LOD archives. This works for
-- any mod without pre-captured data files.
local states = require("MMCheat/util/states")
local blvreader = require("MMCheat/util/image/blvreader")

local M = {
	data = {},
}

function M.init()
end

function M.cleanup()
	M.data = {}
end

states.register_cleanup(M.cleanup)

-- map_name: the map's real file name, with or without the .blv extension
-- (e.g. "d07" or "d07.blv"), as found in Game.MapStats / Map.Name.
-- without_cache: (boolean, optional): if true, don't store the result in the
-- in-memory cache (but if already cached, the cache is still used)
-- Returns:
-- {
-- 	min_x = min_x,
-- 	min_y = min_y,
-- 	max_x = max_x,
-- 	max_y = max_y,
-- 	lines = lines ({x1 = x1, y1 = y1, x2 = x2, y2 = y2})
-- }
-- in game coordinates, or nil if the map cannot be read.
-- All outlines are included, both visible and invisible.
function M.get_map(map_name, without_cache)
	if not map_name then
		return nil
	end
	local base = map_name:lower():match("^(.*)%.blv$") or map_name:lower()

	if M.data[base] then
		return M.data[base]
	end

	local map

	-- currently loaded indoor map: read straight from game memory
	local current_base
	pcall(function()
		current_base = Map.Name:lower():match("^(.*)%.[^%.]+$") or Map.Name:lower()
	end)
	if current_base == base then
		map = blvreader.read_current_map()
	end

	-- any other map (or memory read failed): read the blv from the lod archives
	if not map then
		local err
		map, err = blvreader.read_map(base .. ".blv")
		if not map and err then
			print("MMCheat indoor2dmap: " .. tostring(err))
		end
	end

	if map and not without_cache then
		M.data[base] = map
	end
	return map
end

-- stroke_width (number, optional): Thickness of the SVG lines (default is 10)
-- max_nominal_size (number, optional): Fixed nominal max(width, height) of the SVG output. If nil, it uses default number 1024. If <= 0, it uses coordinate width and height
-- padding (number, optional): padding to add to the border. Use game coordinate system's unit (default is 100)
-- without_cache: (boolean, optional): if true, don't store the map data in the in-memory cache
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
