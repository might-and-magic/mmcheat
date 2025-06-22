local M = {}

M.portrait_sizes = {
	char = {
		width = 59,
		height = 79
	},
	npc = {
		width = 63,
		height = 73
	}
}

-- faces and voice tables are 0-based ([0, Game.PlayerFaces.Count-1])
-- face filename is a prefix like "pc01-" in mm8/mmmerge, "pc01-01" is good condition face
function M.get_face_count()
	if Merge == nil then
		return Game.PlayerFaces.Count
	end
	return Game.CharacterPortraits.Count
end

function M.get_face_prefix_by_index(index)
	if Merge == nil then
		return Game.PlayerFaces[index]
	end
	local char_portrait = Game.CharacterPortraits[index]
	if char_portrait then
		return char_portrait.FacePrefix
	end
	return nil
end

-- It's possible image file with the returned filename doesn't exist
function M.get_good_cond_face_filename_by_index(index)
	local i = tonumber(index)
	local prefix = M.get_face_prefix_by_index(i)
	if prefix == nil then
		return nil
	end
	return prefix .. "01"
end

M.char_face_transparent_color = nil
if Game.Version == 7 then
	M.char_face_transparent_color = "cyan"
end

-- 1 will return "npc0001"
-- no max
local npc_pic_digits
if Game.Version == 6 or Game.Version == 7 then
	npc_pic_digits = 3
else
	npc_pic_digits = 4
end
function M.get_filename_by_npc_pic_index(index)
	return string.format("npc%0" .. npc_pic_digits .. "d", index)
end

local voice_to_sound_id = {
	-- mm6
	{
		[0] = { 5084, 5085 },
		[1] = { 5184, 5185 },
		[2] = { 5284, 5285 },
		[3] = { 5384, 5385 },
		[4] = { 5484, 5485 },
		[5] = { 5584, 5565 }, -- 5 character's second choose-me voice doesn't exist in mm6 and merge, we use "hello" (malef32b, 5565) sound here
		[6] = { 5684, 5685 },
		[7] = { 5784, 5785 },
		[8] = { 5884, 5885 },
		[9] = { 5984, 5985 },
		[10] = { 6084, 6085 },
		[11] = { 6184, 6185 },
	},
	-- mm7
	{
		[0] = { 5006, 5007 },
		[1] = { 5106, 5107 },
		[2] = { 5206, 5207 },
		[3] = { 5306, 5307 },
		[4] = { 5406, 5407 },
		[5] = { 5506, 5507 },
		[6] = { 5606, 5607 },
		[7] = { 5706, 5707 },
		[8] = { 5806, 5807 },
		[9] = { 5906, 5907 },
		[10] = { 6106, 6107 },
		[11] = { 6007, 6006 },
		[12] = { 6206, 6207 },
		[13] = { 6306, 6307 },
		[14] = { 6406, 6407 },
		[15] = { 6506, 6507 },
		[16] = { 6606, 6607 },
		[17] = { 6706, 6707 },
		[18] = { 6806, 6807 },
		[19] = { 6906, 6907 },
		[20] = { 7006, 7007 },
		[21] = { 7106, 7107 },
		[23] = { 7306, 7307 },
		[24] = { 7406, 7407 },
	},
	-- mm8
	{
		[0] = { 5006, 5007 },
		[1] = { 5106, 5107 },
		[2] = { 5206, 5207 },
		[3] = { 5306, 5307 },
		[4] = { 5406, 5407 },
		[5] = { 5506, 5507 },
		[6] = { 5606, 5607 },
		[7] = { 5706, 5707 },
		[8] = { 5806, 5807 },
		[9] = { 5906, 5907 },
		[10] = { 6006, 6007 },
		[11] = { 6106, 6107 },
		[12] = { 6206, 6207 },
		[13] = { 6306, 6307 },
		[14] = { 6406, 6407 },
		[15] = { 6506, 6507 },
		[16] = { 6606, 6607 },
		[17] = { 6706, 6707 },
		[18] = { 6806, 6807 },
		[19] = { 6906, 6907 },
		[20] = { 7006, 7007 },
		[21] = { 7106, 7107 },
		[22] = { 7206, 7207 },
		[23] = { 7306, 7307 },
		[24] = { 7465, 7462 },
		[25] = { 7565, 7562 },
		[26] = { 7606, 7607 },
		[27] = { 7706, 7707 },
		[28] = { 5106, 5107 },
		[29] = { 5206, 5207 },
	} -- dragons uses "hello" sound like in mmmerge
}

-- choose_me_type: 1 or 2 or nil (nil=random)
function M.get_chooseme_sound_index_by_voice_index(voice_index, choose_me_type)
	if choose_me_type == nil then
		choose_me_type = math.random(1, 2)
	end
	if Merge == nil then
		local voice_to_sound_id_i = voice_to_sound_id[Game.Version - 5]
		if voice_to_sound_id_i then
			local voice_to_sound_id_i_i = voice_to_sound_id_i[voice_index]
			if voice_to_sound_id_i_i then
				return voice_to_sound_id_i_i[choose_me_type]
			end
		end
		return nil
	end
	if voice_index == 47 and choose_me_type == 2 then -- 5's second choose-me voice
		return 44363
	end
	local voice_data = Game.CharacterVoices.Sounds
	if voice_data then
		local voice_data_i = voice_data[voice_index]
		if voice_data_i then
			return voice_data_i[choose_me_type + 5]
		end
	end
	return nil
end

function M.play_chooseme_sound_by_voice_index(voice_index, choose_me_type)
	local sound_index = M.get_chooseme_sound_index_by_voice_index(voice_index, choose_me_type)
	if sound_index ~= nil then
		evt.PlaySound(sound_index)
	end
end

return M
