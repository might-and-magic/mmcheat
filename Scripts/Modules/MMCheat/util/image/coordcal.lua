local M = {}

local function round(num)
	if num >= 0 then
		return math.floor(num + 0.5)
	else
		return math.ceil(num - 0.5)
	end
end

-- For a square bitmap image representing a game map:
-- The square bitmap image is size_bitmap x size_bitmap, bottom left point is (0, 0), top right point is (size_bitmap, size_bitmap)
-- It represents a game map. With the in-game coordinates, it has these infomations: x_min, y_min, size_coord. So bottom left point is (x_min, y_min), top right point is (x_min + size_coord, y_min + size_coord)

-- Convert bitmap coordinates to game coordinates
-- params = {x_bitmap, y_bitmap, size_bitmap, x_min, y_min, size_coord, should_round}
function M.bitmap_to_coords(params)
	local x_bitmap = params.x_bitmap
	local y_bitmap = params.y_bitmap
	local size_bitmap = params.size_bitmap
	local x_min = params.x_min
	local y_min = params.y_min
	local size_coord = params.size_coord
	local should_round = params.should_round == nil and true or params.should_round

	-- Convert bitmap coordinates to normalized coordinates (0 to 1)
	local norm_x = x_bitmap / size_bitmap
	local norm_y = y_bitmap / size_bitmap

	-- Scale to game coordinate system
	local x_coord = x_min + norm_x * size_coord
	local y_coord = y_min + norm_y * size_coord

	if should_round then
		x_coord = math.min(math.max(round(x_coord), x_min), x_min + size_coord)
		y_coord = math.min(math.max(round(y_coord), y_min), y_min + size_coord)
	end

	return x_coord, y_coord
end

-- Convert game coordinates to bitmap coordinates
-- params = {x_coord, y_coord, size_bitmap, x_min, y_min, size_coord}
function M.coords_to_bitmap(params)
	local x_coord = params.x_coord
	local y_coord = params.y_coord
	local size_bitmap = params.size_bitmap
	local x_min = params.x_min
	local y_min = params.y_min
	local size_coord = params.size_coord

	-- Convert game coordinates to normalized coordinates (0 to 1)
	local norm_x = (x_coord - x_min) / size_coord
	local norm_y = (y_coord - y_min) / size_coord

	-- Scale to bitmap coordinates
	local x_bitmap = norm_x * size_bitmap
	local y_bitmap = norm_y * size_bitmap

	return x_bitmap, y_bitmap
end

--[[
    Computes the bounding square that centers a given rectangle,
    with a specified margin added on all sides.

    Parameters:
        minX (number) - Minimum X coordinate of the rectangle
        minY (number) - Minimum Y coordinate of the rectangle
        maxX (number) - Maximum X coordinate of the rectangle
        maxY (number) - Maximum Y coordinate of the rectangle

    Returns:
        x_min (number) - Minimum X coordinate of the outer square
        y_min (number) - Minimum Y coordinate of the outer square
        size  (number) - Width and height of the outer square
]]
function M.cal_square_bounds(minX, minY, maxX, maxY)
	-- Calculate width and height of the rectangle
	local rectWidth = maxX - minX
	local rectHeight = maxY - minY

	-- Compute center of the rectangle
	local centerX = (minX + maxX) / 2
	local centerY = (minY + maxY) / 2

	-- Determine size of the square
	local size = math.max(rectWidth, rectHeight) -- + margin * 2

	-- Calculate min x and y of the square
	local x_min = centerX - size / 2
	local y_min = centerY - size / 2

	return x_min, y_min, size
end

return M
