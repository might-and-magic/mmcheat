local ImageLabel = require("MMCheat/ui/components/ImageLabel")
local mmimage = require("MMCheat/util/image/mmimage")
local utils = require("MMCheat/util/utils")
local coordcal = require("MMCheat/util/image/coordcal")
local indoor2dmap = require("MMCheat/util/image/indoor2dmap")

local M = {}

------------------AngleDiagram------------------

local function angle_diagram_draw_circle(width, height, thickness, rgb)
	width = width or 25
	height = height or 25
	thickness = thickness or 1

	local radius = width / 2 - 1
	local center_x, center_y = width / 2, height / 2
	local circle_pixels = {}

	-- Draw anti-aliased black ring
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local dx = x + 0.5 - center_x
			local dy = y + 0.5 - center_y
			local dist = math.sqrt(dx * dx + dy * dy)

			local alpha = 0
			local inner = radius - thickness
			if dist >= inner - 1 and dist <= radius + 1 then
				if dist < inner then
					alpha = 0
				elseif dist < inner + 1 then
					alpha = math.floor(255 * (dist - inner)) -- fade in
				elseif dist < radius then
					alpha = 255
				elseif dist < radius + 1 then
					alpha = math.floor(255 * (radius + 1 - dist)) -- fade out
				end
			end

			table.insert(circle_pixels, rgb[1]) -- R
			table.insert(circle_pixels, rgb[2]) -- G
			table.insert(circle_pixels, rgb[3]) -- B
			table.insert(circle_pixels, alpha) -- A
		end
	end
	return circle_pixels
end

local function angle_diagram_draw_line(angle, rgb, circle_pixels)
	local width, height = 25, 25
	local radius = width / 2 - 1
	local center_x, center_y = width / 2, height / 2

	local function ipart(x)
		return math.floor(x)
	end
	local function round(x)
		return math.floor(x + 0.5)
	end
	local function fpart(x)
		return x - math.floor(x)
	end
	local function rfpart(x)
		return 1 - fpart(x)
	end

	-- Copy circle pixels
	local pixels = {}
	for i = 1, #circle_pixels do -- this is safer than unpack in older Lua
		pixels[i] = circle_pixels[i]
	end

	-- Angle to endpoint
	local theta = (angle % 2048) * (2 * math.pi / 2048)
	local x1, y1 = center_x, center_y
	local x2 = center_x + math.cos(theta) * (radius - 0.5)
	local y2 = center_y - math.sin(theta) * (radius - 0.5)

	-- Swap axis if slope > 1
	local steep = math.abs(y2 - y1) > math.abs(x2 - x1)
	if steep then
		x1, y1, x2, y2 = y1, x1, y2, x2
	end
	if x1 > x2 then
		x1, x2, y1, y2 = x2, x1, y2, y1
	end

	local dx = x2 - x1
	local dy = y2 - y1
	local gradient = dx == 0 and 1 or dy / dx

	local function plot(xx, yy, alpha)
		if steep then
			xx, yy = yy, xx
		end
		local x = math.floor(xx)
		local y = math.floor(yy)
		if x >= 0 and x < width and y >= 0 and y < height then
			local idx = (y * width + x) * 4
			pixels[idx + 1] = rgb[1] -- R
			pixels[idx + 2] = rgb[2] -- G
			pixels[idx + 3] = rgb[3] -- B
			pixels[idx + 4] = math.max(pixels[idx + 4] or 0, math.floor(alpha * 255))
		end
	end

	local xend = round(x1)
	local yend = y1 + gradient * (xend - x1)
	local xgap = rfpart(x1 + 0.5)
	local xpxl1 = xend
	local ypxl1 = ipart(yend)
	plot(xpxl1, ypxl1, rfpart(yend) * xgap)
	plot(xpxl1, ypxl1 + 1, fpart(yend) * xgap)

	local intery = yend + gradient

	xend = round(x2)
	yend = y2 + gradient * (xend - x2)
	xgap = fpart(x2 + 0.5)
	local xpxl2 = xend
	local ypxl2 = ipart(yend)
	plot(xpxl2, ypxl2, rfpart(yend) * xgap)
	plot(xpxl2, ypxl2 + 1, fpart(yend) * xgap)

	for x = xpxl1 + 1, xpxl2 - 1 do
		plot(x, ipart(intery), rfpart(intery))
		plot(x, ipart(intery) + 1, fpart(intery))
		intery = intery + gradient
	end

	return pixels
end

local AngleDiagram = {}

AngleDiagram.__index = AngleDiagram

function AngleDiagram:new(diameter, thickness, rgb_circle, rgb_line, handle_name)
	local circle_pixels = angle_diagram_draw_circle(diameter, diameter, thickness, rgb_circle)
	local image_label_obj = ImageLabel:new({
		width = diameter,
		height = diameter,
		pixels = circle_pixels,
		context_menu = false
	})
	local obj = {
		image_label_obj = image_label_obj,
		label = image_label_obj.label,
		diameter = diameter,
		thickness = thickness,
		rgb_circle = rgb_circle,
		rgb_line = rgb_line,
		circle_pixels = circle_pixels
	}
	setmetatable(obj, self)
	return obj
end

function AngleDiagram:draw_line(angle)
	local angle_diagram_pixels = angle_diagram_draw_line(angle, self.rgb_line, self.circle_pixels)
	self.image_label_obj:load_pixels(self.diameter, self.diameter, angle_diagram_pixels)
end

-- Usage:
-- local angle_diagram1 = draw.AngleDiagram:new(25, 1, {0, 0, 0}, {255, 0, 0})
-- angle_diagram1:draw_line(30)

M.AngleDiagram = AngleDiagram

------------------lines_pixels------------------

-- Plot a single pixel in the bitmap (set to black), Y-axis flipped
local function plot_pixel(bitmap, x, y, size_bitmap, r, g, b)
	if x < 1 or x > size_bitmap or y < 1 or y > size_bitmap then
		return
	end
	-- local new_y = size_bitmap - y + 1 -- flip y axis: new_y is inverted y
	-- local idx = ((new_y - 1) * size_bitmap + (x - 1)) * 3 + 1
	local idx = ((y - 1) * size_bitmap + (x - 1)) * 3 + 1
	bitmap[idx] = r  -- Red
	bitmap[idx + 1] = g -- Green
	bitmap[idx + 2] = b -- Blue
end

-- Bresenham line drawing on RGB bitmap
local function draw_line(bitmap, size_bitmap, x0, y0, x1, y1)
	local dx = math.abs(x1 - x0)
	local dy = math.abs(y1 - y0)
	local sx = x0 < x1 and 1 or -1
	local sy = y0 < y1 and 1 or -1
	local err = dx - dy

	while true do
		plot_pixel(bitmap, x0, y0, size_bitmap, 0, 0, 0) -- black pixel
		if x0 == x1 and y0 == y1 then
			break
		end
		local e2 = 2 * err
		if e2 > -dy then
			err = err - dy
			x0 = x0 + sx
		end
		if e2 < dx then
			err = err + dx
			y0 = y0 + sy
		end
	end
end

--[[
Generates a 24-bit RGB bitmap representation of the dungeon map from line data.

@param map_data      Table containing map coordinates and line segments:
                     {
                       min_x = number,
                       min_y = number,
                       max_x = number,
                       max_y = number,
                       lines = { {x1, y1, x2, y2}, ... }
                     }
@param x_min         Minimum X coordinate of the map area to render
@param y_min         Minimum Y coordinate of the map area to render
@param size_coord    Width/height of the square map area in game coordinate units
@param size_bitmap   Width/height (pixels) of the square output bitmap

@return bitmap       A flat 1D array representing the RGB pixel data of the bitmap,
                     with 3 bytes per pixel (R, G, B),
                     row-major order (top-left pixel first).

Notes:
- The bitmap background is white (255,255,255).
- Lines are drawn in black (0,0,0) with a 1-pixel width using Bresenham's line algorithm.
- Coordinates outside the specified bounds are clamped to the bitmap edges.
- No anti-aliasing is applied.

Usage example:
local bitmap = lines_pixels(map_data, -22528, -22528, 45056, 355)
-- bitmap now contains RGB pixel data you can write to a file or further process.
--]]
function M.lines_pixels(map_data, x_min, y_min, size_coord, size_bitmap)
	-- Initialize bitmap: white background RGB(255,255,255)
	local pixel_count = size_bitmap * size_bitmap
	local bitmap = {}
	for i = 1, pixel_count * 3 do
		bitmap[i] = 255
	end

	-- Convert world coordinates to pixel indices
	local function world_to_pixel(x, y)
		-- Normalize to [0,1]
		local nx = (x - x_min) / size_coord
		local ny = (y - y_min) / size_coord
		-- Clamp
		nx = math.min(math.max(nx, 0), 1)
		ny = math.min(math.max(ny, 0), 1)
		-- Convert to pixel coordinates [1..size_bitmap]
		local px = math.floor(nx * (size_bitmap - 1)) + 1
		local py = math.floor((1 - ny) * (size_bitmap - 1)) + 1 -- invert y for image coords (top-left origin)
		return px, py
	end

	-- Draw all lines
	for _, line in ipairs(map_data.lines) do
		local x1, y1, x2, y2 = line.x1, line.y1, line.x2, line.y2
		local px1, py1 = world_to_pixel(x1, y1)
		local px2, py2 = world_to_pixel(x2, y2)
		draw_line(bitmap, size_bitmap, px1, py1, px2, py2)
	end

	return bitmap
end

------------------CoordMap------------------

local CoordMap = {}

CoordMap.__index = CoordMap

function CoordMap:new(size_bitmap, rgb_dot, size_dot)
	local image_label_obj = ImageLabel:new({
		width = size_bitmap,
		height = size_bitmap
	})
	local obj = {
		image_label_obj = image_label_obj,
		label = image_label_obj.label,
		size_bitmap = size_bitmap,
		rgb_dot = rgb_dot,
		size_dot = size_dot
	}
	setmetatable(obj, self)
	return obj
end

-- self.? list:
-- image_label_obj: hold the instance of ImageLabel
-- label: holds the image_label_obj.label which is the iup.label
-- size_bitmap: the width/height of the bitmap
-- rgb_dot: the color of the dot
-- size_dot: the size (diameter) of the dot
-- x_min: the minimum x coordinate of the map
-- y_min: the minimum y coordinate of the map
-- size_coord: the width/height in coordinate system of the map
-- coord_map_pixels: holds the (base) pixels of the current map
-- coord_map_index: holds the index of the current map

function CoordMap:load_map(map_index)
	if map_index and map_index > 0 and map_index ~= self.coord_map_index then -- index changed, load new map pixels
		local is_outdoor = utils.mapconv.is_outdoor_by_index(map_index)
		local filename = utils.mapconv.index_to_filename(map_index)
		-- Remove extension from filename
		local map_name = filename:match("(.+)%..+$") or filename
		if is_outdoor then
			local bitmap_info = mmimage.get_bitmap_info_by_filename(map_name)
			if not bitmap_info then
				self.x_min = -const.MapLimit
				self.y_min = -const.MapLimit
				self.size_coord = 2 * const.MapLimit
				self.coord_map_pixels = nil
				self.image_label_obj:set_use_svg(false)
				self.image_label_obj:set_map_xy({})
				self.image_label_obj:set_filename(nil)
			else
				local old_height = bitmap_info.Height
				self.coord_map_pixels = mmimage.mem_to_bmp_pixel_data_flat_rgb(bitmap_info, utils.get_map_cut(old_height))
				-- after cut, width and height will always be `utils.map_image_size` (355)
				self.x_min = -const.MapLimit
				self.y_min = -const.MapLimit
				self.size_coord = 2 * const.MapLimit
				self.image_label_obj:set_use_svg(false)
				self.image_label_obj:set_map_xy({
					x_min = self.x_min,
					x_max = self.x_min + self.size_coord,
					y_min = self.y_min,
					y_max = self.y_min + self.size_coord
				})
				self.image_label_obj:set_filename(map_name)
			end
		else -- indoor
			local map_data = indoor2dmap.get_map(map_name)
			if not map_data then
				self.x_min = -const.MapLimit
				self.y_min = -const.MapLimit
				self.size_coord = 2 * const.MapLimit
				self.coord_map_pixels = nil
				self.image_label_obj:set_use_svg(false)
				self.image_label_obj:set_map_xy({})
				self.image_label_obj:set_filename(nil)
			else
				local x_min, y_min, size = coordcal.cal_square_bounds(map_data.min_x, map_data.min_y, map_data.max_x,
					map_data.max_y)
				-- print("x_min_coord", x_min, "y_min_coord", y_min, "size_coord", size, "x_min_bitmap", 0, "y_min_bitmap", 0, "size_bitmap", self.size_bitmap)
				self.x_min = x_min
				self.y_min = y_min
				self.size_coord = size
				self.coord_map_pixels = M.lines_pixels(map_data, self.x_min, self.y_min, self.size_coord,
					self.size_bitmap)
				self.image_label_obj:set_use_svg(true)
				self.image_label_obj:set_map_xy({
					x_min = map_data.min_x,
					x_max = map_data.max_x,
					y_min = map_data.min_y,
					y_max = map_data.max_y
				})
				self.image_label_obj:set_filename(map_name)
			end
		end
		self.coord_map_index = map_index
		self.image_label_obj:set_alt_pixels_to_save(self.coord_map_pixels)
	end
end

function CoordMap:draw_dot_by_coords(x, y)
	local x_pixel, y_pixel = coordcal.coords_to_bitmap({
		x_coord = x,
		y_coord = y,
		size_bitmap = self.size_bitmap,
		x_min = self.x_min,
		y_min = self.y_min,
		size_coord = self.size_coord
	})
	local dot_pixels = M.coords_diagram_draw_dot(x_pixel, y_pixel, self.rgb_dot, self.size_dot, self.coord_map_pixels,
		self.size_bitmap, true)
	self.image_label_obj:load_pixels(self.size_bitmap, self.size_bitmap, dot_pixels)
end

function CoordMap:bitmap_to_coords(x_pixel, y_pixel)
	return coordcal.bitmap_to_coords({
		x_bitmap = x_pixel,
		y_bitmap = y_pixel,
		size_bitmap = self.size_bitmap,
		x_min = self.x_min,
		y_min = self.y_min,
		size_coord = self.size_coord,
		should_round = true
	})
end

function CoordMap:coords_to_bitmap(x, y)
	return coordcal.coords_to_bitmap({
		x_coord = x,
		y_coord = y,
		size_bitmap = self.size_bitmap,
		x_min = self.x_min,
		y_min = self.y_min,
		size_coord = self.size_coord
	})
end

M.CoordMap = CoordMap

--[[
Draws a circular dot on a square bitmap with optional border.

Parameters:
  dot_x (number): X coordinate as pixel and can be float number, where 0 is left edge
  dot_y (number): Y coordinate as pixel and can be float number, where 0 is bottom edge
  dot_rgb (table): Color of the dot, either {r=255, g=0, b=0} or {255, 0, 0} format (don't use alpha channel)
  dot_size (number): Diameter of the dot in pixels
  square_pixels (table): Flat array of pixel data (RGB or RGBA format) representing the original bitmap, if nil, will use RGBA format and square bitmap all filled with transparent (255, 255, 255, 255)
  square_width (number): Width/height
  when_nil_use_rgb_white (boolean): If true, will use RGB white (255, 255, 255) when square_pixels is nil, otherwise will use RGBA transparent (255, 255, 255, 0)

Returns:
  table: New flat array of pixel data with the dot drawn, same format as input

Notes:
  - Uses bottom-left origin coordinate system (0,0 is bottom-left corner)
  - Dot will be clipped if it extends beyond the bitmap boundaries
  - Does not modify the original square_pixels array
  - Auto-detects RGB vs RGBA format based on input data
--]]
function M.coords_diagram_draw_dot(dot_x, dot_y, dot_rgb, dot_size, square_pixels, square_width, when_nil_use_rgb_white)
	local pixels = {}

	local components_per_pixel
	if square_pixels and #square_pixels > 0 then
		components_per_pixel = #square_pixels / (square_width * square_width)
		-- Copy square pixels
		for i = 1, #square_pixels do
			pixels[i] = square_pixels[i]
		end
	else
		if when_nil_use_rgb_white then
			for i = 1, square_width * square_width do
				table.insert(pixels, 255)
				table.insert(pixels, 255)
				table.insert(pixels, 255)
			end
			components_per_pixel = 3
		else
			for i = 1, square_width * square_width do
				table.insert(pixels, 255)
				table.insert(pixels, 255)
				table.insert(pixels, 255)
				table.insert(pixels, 0)
			end
			components_per_pixel = 4
		end
	end

	-- Flip y to make (0,0) bottom-left (following your working logic)
	local y_flipped = square_width - dot_y

	-- Use pixel coordinates directly (with rounding for pixel center)
	local px = math.floor(dot_x + 0.5)
	local py = math.floor(y_flipped + 0.5)

	local radius = math.floor(dot_size / 2)

	for iy = -radius, radius do
		for ix = -radius, radius do
			if ix * ix + iy * iy <= radius * radius then
				local xi = px + ix
				local yi = py + iy
				if xi >= 0 and xi < square_width and yi >= 0 and yi < square_width then
					-- Check if we're using RGBA (4 components) or RGB (3 components)
					local idx = (yi * square_width + xi) * components_per_pixel

					if components_per_pixel == 4 then
						-- RGBA format
						pixels[idx + 1] = dot_rgb.r or dot_rgb[1]
						pixels[idx + 2] = dot_rgb.g or dot_rgb[2]
						pixels[idx + 3] = dot_rgb.b or dot_rgb[3]
						pixels[idx + 4] = 255 -- Alpha
					else
						-- RGB format
						pixels[idx + 1] = dot_rgb.r or dot_rgb[1]
						pixels[idx + 2] = dot_rgb.g or dot_rgb[2]
						pixels[idx + 3] = dot_rgb.b or dot_rgb[3]
					end
				end
			end
		end
	end

	return pixels
end

function M.coords_to_angle(x, y, size, is_lookangle)
	is_lookangle = is_lookangle or false

	local cx = (size - 1) / 2
	local cy = (size - 1) / 2

	local dx = x - cx
	local dy = cy - y -- invert Y axis (screen space to Cartesian)

	if dx == 0 and dy == 0 then
		return 0
	end

	---@diagnostic disable-next-line: deprecated
	local radians = math.atan2(dy, dx) -- [-pi, pi]
	if radians < 0 then
		radians = radians + 2 * math.pi -- convert to [0, 2pi)
	end

	local angle = math.floor(radians * (2048 / (2 * math.pi)) + 0.5) -- [0, 2048)
	if angle == 2048 then
		angle = 0
	end

	if not is_lookangle then
		return angle -- regular angle in [0, 2047]
	end

	-- Convert to [-1023, 1024] look angle
	local lookangle = angle
	if lookangle > 1024 then
		lookangle = lookangle - 2048
	end

	-- Wrap to [-1023, 1024]
	if lookangle < -1023 then
		lookangle = -1023 + ((lookangle + 1023) % 2048)
	elseif lookangle > 1024 then
		lookangle = 1024 - ((lookangle - 1024) % 2048)
	end

	return lookangle
end

return M
