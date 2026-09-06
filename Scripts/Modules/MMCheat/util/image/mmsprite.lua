local bit = require("bit")

local M = {}

local palette_manager = Game.Version == 6 and 0x762D80 or (Game.Version == 7 and 0x80D018 or 0x84AFE0)
local full_brightness_palette_offset = 0x9600

local function append_transparent_pixel(pixels)
	pixels[#pixels + 1] = 0
	pixels[#pixels + 1] = 0
	pixels[#pixels + 1] = 0
	pixels[#pixels + 1] = 0
end

local function append_palette_pixel(pixels, palette_ptr, palette_index)
	local value = mem.u2[palette_ptr + palette_index * 2]
	pixels[#pixels + 1] = math.floor(bit.rshift(value, 11) * 255 / 31 + 0.5)
	pixels[#pixels + 1] = math.floor(bit.band(bit.rshift(value, 5), 0x3F) * 255 / 63 + 0.5)
	pixels[#pixels + 1] = math.floor(bit.band(value, 0x1F) * 255 / 31 + 0.5)
	pixels[#pixels + 1] = 255
end

local function get_standing_sprite(monster_id)
	local monster_graphics = Game.MonListBin[monster_id]
	if not monster_graphics or monster_graphics.FramesStand == "" then
		return
	end

	local group_name = monster_graphics.FramesStand
	local group_id = Game.SFTBin:FindGroup(group_name)
	if not group_id or group_id < 0 then
		return
	end

	local frame = Game.SFTBin[group_id]
	if frame.GroupName:lower() ~= group_name:lower() then
		return
	end

	-- Loading only the front image avoids filling the sprite cache with all eight
	-- orientations and every animation frame while the user browses the list.
	local sprite_filename = frame.SpriteName .. (frame.Image1 and "" or "0")
	local sprite_index = Game.SpritesLod:LoadSprite(sprite_filename, frame.PaletteId)
	if sprite_index < 0 then
		return
	end

	local sprite = Game.SpritesLod.SpritesSW[sprite_index]
	if sprite.Width <= 0 or sprite.Height <= 0 or sprite.Lines["?ptr"] == 0 then
		return
	end

	return sprite, Game.LoadPalette(frame.PaletteId), sprite.Name
end

local function get_opaque_bounds(sprite)
	local left = sprite.Width
	local right = -1
	local top = sprite.Height
	local bottom = -1

	for y = 0, sprite.Height - 1 do
		local line = sprite.Lines[y]
		if line.Pos["?ptr"] ~= 0 and line.L >= 0 and line.R >= line.L then
			left = math.min(left, line.L)
			right = math.max(right, line.R)
			top = math.min(top, y)
			bottom = math.max(bottom, y)
		end
	end

	if right < left or bottom < top then
		return
	end
	return left, right, top, bottom
end

function M.get_monster_preview(monster_id, target_width, target_height)
	local sprite, palette_index, sprite_name = get_standing_sprite(monster_id)
	if not sprite then
		return
	end

	local left, right, top, bottom = get_opaque_bounds(sprite)
	if not left then
		return
	end

	local padding = 6
	local source_width = right - left + 1
	local source_height = bottom - top + 1
	local scale = math.min((target_width - padding * 2) / source_width,
		(target_height - padding * 2) / source_height)
	local scaled_width = math.max(1, math.floor(source_width * scale + 0.5))
	local scaled_height = math.max(1, math.floor(source_height * scale + 0.5))
	local offset_x = math.floor((target_width - scaled_width) / 2)
	local offset_y = math.floor((target_height - scaled_height) / 2)
	local palette_ptr = palette_manager + palette_index * 0x4000 + full_brightness_palette_offset
	local pixels = {}

	for y = 0, target_height - 1 do
		for x = 0, target_width - 1 do
			if x >= offset_x and x < offset_x + scaled_width and y >= offset_y and y < offset_y + scaled_height then
				local source_x = left + math.min(source_width - 1, math.floor((x - offset_x) / scale))
				local source_y = top + math.min(source_height - 1, math.floor((y - offset_y) / scale))
				local line = sprite.Lines[source_y]
				if line.Pos["?ptr"] ~= 0 and source_x >= line.L and source_x <= line.R then
					local color_index = line.Pos[source_x - line.L]
					if color_index ~= 0 then
						append_palette_pixel(pixels, palette_ptr, color_index)
					else
						append_transparent_pixel(pixels)
					end
				else
					append_transparent_pixel(pixels)
				end
			else
				append_transparent_pixel(pixels)
			end
		end
	end

	return {
		width = target_width,
		height = target_height,
		pixels = pixels,
		filename = sprite_name
	}
end

return M
