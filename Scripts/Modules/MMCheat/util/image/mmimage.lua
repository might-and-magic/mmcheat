local bit = require("bit")

local M = {}

function M.mem_to_bmp_pixel_data_flat_rgb(bitmap_info, cut)
	local width = bitmap_info.Width
	local height = bitmap_info.Height
	local image_ptr = bitmap_info.Image
	local palette_ptr = bitmap_info.Palette16
	local datasize = bitmap_info.DataSize or (width * height)

	-- Initialize cut values, defaulting to 0 if not provided
	local cut_top = cut and cut.top or 0
	local cut_right = cut and cut.right or 0
	local cut_bottom = cut and cut.bottom or 0
	local cut_left = cut and cut.left or 0

	local rgb_data = {}

	-- Calculate the effective dimensions after cutting
	local effective_width = math.max(0, width - cut_left - cut_right)
	local effective_height = math.max(0, height - cut_top - cut_bottom)

	-- If effective_width or effective_height is 0 or less, return empty data
	if effective_width <= 0 or effective_height <= 0 then
		return {}
	end

	-- Iterate through the effective area
	for y = cut_top, height - 1 - cut_bottom do
		for x = cut_left, width - 1 - cut_right do
			-- Calculate the linear index for the original image data
			local original_index = y * width + x

			-- Ensure we don't go out of bounds for the original image data
			if original_index < datasize then
				local index = mem.u1[image_ptr + original_index] -- palette index

				-- Read RGB565 value (2 bytes per entry)
				local value = mem.u2[palette_ptr + index * 2]

				-- Extract and scale components
				local r = math.floor(bit.rshift(value, 11) * 255 / 31 + 0.5)
				local g = math.floor(bit.band(bit.rshift(value, 5), 0x3F) * 255 / 63 + 0.5)
				local b = math.floor(bit.band(value, 0x1F) * 255 / 31 + 0.5)

				table.insert(rgb_data, r)
				table.insert(rgb_data, g)
				table.insert(rgb_data, b)
			end
		end
	end

	return rgb_data
end

function M.get_bitmap_info_by_filename(filename)
	local bitmap_index = Game.IconsLod:LoadBitmap(filename)
	if not bitmap_index or bitmap_index == 0 then
		return nil
	end
	return Game.IconsLod.Bitmaps[bitmap_index]
end

-- Get interval index of a timestamp dividing one day into N intervals
-- The day is 24 * 60 * 256 ticks long.
-- Intervals are 0-based: first interval is 0, last interval is N-1.
local function timestamp_to_interval_index(timestamp, n)
	local ticks_per_day = 24 * 60 * const.Minute
	local ticks_per_interval = ticks_per_day / n

	local ticks_in_day = timestamp % ticks_per_day
	local interval_index = math.floor(ticks_in_day / ticks_per_interval)

	return interval_index
end

local function timestamp_to_terra_string(timestamp, n, digits)
	local interval_index = timestamp_to_interval_index(timestamp, n)
	local format_str = "terra%0" .. digits .. "d"
	return string.format(format_str, interval_index)
end

M.terra_sizes = {
	width = 444,
	height = 108
}
local terra_count = 240
local terra_digits = 3
if Game.Version == 8 then
	terra_count = 244
	terra_digits = 4
end
function M.get_terra_filename_by_timestamp(timestamp)
	return timestamp_to_terra_string(timestamp, terra_count, terra_digits)
end

function M.export_all_maps(dir, command)
	local utils = require("MMCheat/util/utils")
	local command_name, arg1, arg2, arg3 = utils.parse_command(command)
	if command_name == "@allindoorsvg" then
		for _, map_filename in ipairs(utils.mapconv.map_filenames) do
			if utils.mapconv.is_outdoor(map_filename) == false then
				local stroke_width = arg1
				local max_nominal_size = arg2
				local padding = arg3
				local map_filename_without_ext = map_filename:match("^(.*)%.[^%.]+$") or map_filename
				local normalized_map_filename = utils.normalize_map_filename(map_filename_without_ext)
				local indoor2dmap = require("MMCheat/util/image/indoor2dmap")
				local svg = indoor2dmap.get_map_svg(normalized_map_filename, stroke_width, max_nominal_size, padding,
					true)
				local system = require("MMCheat/util/general/system")
				system.save_text_file(dir .. map_filename_without_ext .. ".svg", svg)
			end
		end
	elseif command_name == "@allindoorbmp" then
		for _, map_filename in ipairs(utils.mapconv.map_filenames) do
			if utils.mapconv.is_outdoor(map_filename) == false then
				local map_image_size = arg1 or utils.map_image_size
				local map_filename_without_ext = map_filename:match("^(.*)%.[^%.]+$") or map_filename
				local normalized_map_filename = utils.normalize_map_filename(map_filename_without_ext)
				local indoor2dmap = require("MMCheat/util/image/indoor2dmap")
				local map_data = indoor2dmap.get_map(normalized_map_filename, true)
				if map_data then
					local coordcal = require("MMCheat/util/image/coordcal")
					local x_min, y_min, size = coordcal.cal_square_bounds(map_data.min_x, map_data.min_y,
						map_data.max_x,
						map_data.max_y)
					local draw = require("MMCheat/util/image/draw")
					local pixels = draw.lines_pixels(map_data, x_min, y_min, size,
						map_image_size)
					local bitmap = require("MMCheat/util/image/bitmap")
					bitmap.save_image_to_bmp_file(dir .. map_filename_without_ext .. ".bmp", pixels,
						map_image_size,
						map_image_size)
				end
			end
		end
	elseif command_name == "@alloutdoorbmp" then
		for _, map_filename in ipairs(utils.mapconv.map_filenames) do
			if utils.mapconv.is_outdoor(map_filename) == true then
				local should_cut
				if arg1 == nil then
					should_cut = 1
				elseif arg1 == false then
					should_cut = 0
				elseif arg1 == true then
					should_cut = 1
				else
					should_cut = arg1
				end
				local map_filename_without_ext = map_filename:match("^(.*)%.[^%.]+$") or map_filename
				local bitmap_info = M.get_bitmap_info_by_filename(map_filename_without_ext)
				if bitmap_info then
					local cut
					local width = bitmap_info.Width
					local height = bitmap_info.Height
					if should_cut == 1 then
						cut = utils.get_map_cut(height)
						width = utils.map_image_size
						height = utils.map_image_size
					end
					local pixels = M.mem_to_bmp_pixel_data_flat_rgb(bitmap_info, cut)
					local bitmap = require("MMCheat/util/image/bitmap")
					bitmap.save_image_to_bmp_file(dir .. map_filename_without_ext .. ".bmp", pixels, width,
						height)
				end
			end
		end
	end
end

return M
