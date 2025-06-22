local bit = require("bit")

local M = {}

function M.bmp_file_to_pixel_data_flat_rgba(filepath)
	local function read_word(data, offset)
		return string.byte(data, offset + 1) + string.byte(data, offset + 2) * 256
	end

	local function read_dword(data, offset)
		return string.byte(data, offset + 1) + string.byte(data, offset + 2) * 256 + string.byte(data, offset + 3) *
			65536 + string.byte(data, offset + 4) * 16777216
	end

	local function read_long(data, offset)
		local val = read_dword(data, offset)
		if val >= 0x80000000 then
			return val - 0x100000000
		end
		return val
	end

	local function get_pixel(data, x, y, width, height, bpp, offset, topdown)
		local Bpp = math.floor(bpp / 8)
		local line_w = math.ceil(width * Bpp / 4) * 4
		local index
		if not topdown then
			y = height - y - 1
		end
		index = offset + y * line_w + x * Bpp
		local b = string.byte(data, index + 1)
		local g = string.byte(data, index + 2)
		local r = string.byte(data, index + 3)
		local a = Bpp == 4 and string.byte(data, index + 4) or 255
		return r, g, b, a
	end

	local file = io.open(filepath, "rb")
	if not file then
		print("Error: Could not open file: " .. filepath)
		return nil
	end

	local data = file:read("*a")
	file:close()

	if not data then
		print("Error: Could not read file data: " .. filepath)
		return nil
	end

	if #data < 54 then
		print("Error: File too small to be a valid BMP file: " .. filepath)
		return nil
	end

	if read_word(data, 0) ~= 0x4D42 then
		print("Error: Not a BMP file: " .. filepath)
		return nil
	end

	local pixel_offset = read_dword(data, 10)
	local width = read_long(data, 18)
	local height = read_long(data, 22)
	local bpp = read_word(data, 28)
	local compression = read_dword(data, 30)

	if compression ~= 0 then
		print("Error: Compressed BMP not supported: " .. filepath)
		return nil
	end

	if bpp ~= 24 and bpp ~= 32 then
		print("Error: Only 24-bit or 32-bit BMP supported, got " .. bpp .. "-bit: " .. filepath)
		return nil
	end

	local topdown = height < 0
	if topdown then
		height = -height
	end

	local pixels = {}
	for y = 0, height - 1 do
		for x = 0, width - 1 do
			local r, g, b, a = get_pixel(data, x, y, width, height, bpp, pixel_offset, topdown)
			table.insert(pixels, r)
			table.insert(pixels, g)
			table.insert(pixels, b)
			table.insert(pixels, a)
		end
	end

	return {
		width = width,
		height = height,
		pixels = pixels
	}
end

local color_keywords = {
	red = { 255, 0, 0 },
	green = { 0, 255, 0 },
	blue = { 0, 0, 255 },
	yellow = { 255, 255, 0 },
	cyan = { 0, 255, 255 },
	magenta = { 255, 0, 255 },
	white = { 255, 255, 255 },
	black = { 0, 0, 0 }
}

local function parse_color(color_str_or_table)
	if type(color_str_or_table) == "table" then
		-- Assume it's already an RGB table {r, g, b}
		return color_str_or_table
	end

	-- Handle rgb(r,g,b)
	local r, g, b = tostring(color_str_or_table):match("rgb%((%d+),%s*(%d+),%s*(%d+)%)")
	if r then
		return {
			r = tonumber(r),
			g = tonumber(g),
			b = tonumber(b)
		}
	end

	-- Handle named color
	local rgb = color_keywords[tostring(color_str_or_table):lower()]
	if rgb then
		return {
			r = rgb[1],
			g = rgb[2],
			b = rgb[3]
		}
	end

	print("Unsupported color format: " .. tostring(color_str_or_table))
	return nil
end

--- Converts flat RGB data to RGBA, making a specific RGB value transparent.
-- @param rgb_data: flat table {r1, g1, b1, r2, g2, b2, ...}
-- @param transparent_color: table {r=R, g=G, b=B} to mark as transparent, or string "red", "green", "blue", "yellow", "cyan", "magenta", "white", "black", in the game the most common transparent replacement color are "cyan", "magenta", sometimes it could also be "red" or "green", or array of such tables/strings (e.g. {{r=R, g=G, b=B}, {r=R, g=G, b=B}} or {{r=R, g=G, b=B}, "red", "green"})
-- @return flat RGBA table
function M.rgb_to_rgba_with_transparency(rgb_data, transparent_color)
	local transparent_rgbs = {}

	if type(transparent_color) == "table" and rawget(transparent_color, 1) then -- Check if it's an array-like table
		for _, color_entry in ipairs(transparent_color) do
			table.insert(transparent_rgbs, parse_color(color_entry))
		end
	else
		table.insert(transparent_rgbs, parse_color(transparent_color))
	end

	local rgba_data = {}

	for i = 1, #rgb_data, 3 do
		local r = rgb_data[i]
		local g = rgb_data[i + 1]
		local b = rgb_data[i + 2]

		local a = 255
		for _, trgb in ipairs(transparent_rgbs) do
			if r == trgb.r and g == trgb.g and b == trgb.b then
				a = 0
				break -- Found a match, no need to check other transparent colors
			end
		end

		table.insert(rgba_data, r)
		table.insert(rgba_data, g)
		table.insert(rgba_data, b)
		table.insert(rgba_data, a)
	end

	return rgba_data
end

-- Save image as raw data
function M.save_image_to_bmp_file(filename, pixels, width, height)
	local f = io.open(filename, "wb")
	if f then
		-- Check if we have valid pixel data
		if not pixels or #pixels == 0 then
			f:close()
			return
		end

		-- Determine if we're dealing with RGB or RGBA
		local is_rgb = #pixels == 3 * width * height
		local bytes_per_pixel = is_rgb and 3 or 4

		-- Calculate padding to make each row 4-byte aligned
		local row_padding = (4 - ((width * bytes_per_pixel) % 4)) % 4
		local row_size = width * bytes_per_pixel + row_padding
		local image_size = row_size * height

		-- Helper function to write little-endian integers
		local function write_le32(n)
			f:write(string.char(bit.band(n, 0xFF), bit.band(bit.rshift(n, 8), 0xFF), bit.band(bit.rshift(n, 16), 0xFF),
				bit.band(bit.rshift(n, 24), 0xFF)))
		end

		local function write_le16(n)
			f:write(string.char(bit.band(n, 0xFF), bit.band(bit.rshift(n, 8), 0xFF)))
		end

		-- BMP Header (14 bytes)
		f:write("BM")          -- Signature
		if is_rgb then
			write_le32(54 + image_size) -- File size
			write_le32(0)      -- Reserved
			write_le32(54)     -- Pixel data offset

			-- DIB Header (BITMAPINFOHEADER - 40 bytes)
			write_le32(40)         -- DIB header size
			write_le32(width)      -- Width
			write_le32(height)     -- Height
			write_le16(1)          -- Color planes
			write_le16(bytes_per_pixel * 8) -- Bits per pixel
			write_le32(0)          -- Compression method
			write_le32(image_size) -- Image size
			write_le32(2835)       -- X pixels per meter
			write_le32(2835)       -- Y pixels per meter
			write_le32(0)          -- Colors in color table
			write_le32(0)          -- Important color count
		else
			write_le32(122 + image_size) -- File size (54 + 68 for V4 header + image size)
			write_le32(0)          -- Reserved
			write_le32(122)        -- Pixel data offset (54 + 68 for V4 header)

			-- DIB Header (BITMAPV4HEADER - 108 bytes)
			write_le32(108)        -- DIB header size (BITMAPV4HEADER)
			write_le32(width)      -- Width
			write_le32(height)     -- Height
			write_le16(1)          -- Color planes
			write_le16(bytes_per_pixel * 8) -- Bits per pixel
			write_le32(3)          -- Compression method (BI_BITFIELDS)
			write_le32(image_size) -- Image size
			write_le32(2835)       -- X pixels per meter
			write_le32(2835)       -- Y pixels per meter
			write_le32(0)          -- Colors in color table
			write_le32(0)          -- Important color count

			-- BITMAPV4HEADER specific fields
			write_le32(0x00FF0000) -- Red mask
			write_le32(0x0000FF00) -- Green mask
			write_le32(0x000000FF) -- Blue mask
			write_le32(0xFF000000) -- Alpha mask
			write_le32(0x73524742) -- Color space type (sRGB)
			-- Color space endpoints (all zeros for sRGB)
			for i = 1, 36 do
				f:write("\0")
			end
			write_le32(0) -- Gamma red
			write_le32(0) -- Gamma green
			write_le32(0) -- Gamma blue
		end

		-- Write pixel data (BMP is stored bottom-up)
		for y = height - 1, 0, -1 do
			for x = 0, width - 1 do
				local idx = (y * width + x) * bytes_per_pixel + 1
				if is_rgb then
					-- BMP stores colors as BGR for RGB images
					f:write(string.char(pixels[idx + 2], -- B
						pixels[idx + 1],  -- G
						pixels[idx]       -- R
					))
				else
					-- BMP stores colors as BGRA for RGBA images
					f:write(string.char(pixels[idx + 2], -- B
						pixels[idx + 1],  -- G
						pixels[idx],      -- R
						pixels[idx + 3]   -- A
					))
				end
			end
			-- Write row padding
			if row_padding > 0 then
				f:write(string.rep("\0", row_padding))
			end
		end

		f:close()
	end
end

return M
