local iup        = require("iup")
local ui         = require("MMCheat/ui/components/ui_components")
local utils      = require("MMCheat/util/utils")
local i18n       = require("MMCheat/i18n/i18n")
local enc        = require("MMCheat/i18n/encoding")
local states     = require("MMCheat/util/states")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")
local facesound  = require("MMCheat/util/image/facesound")

local M          = {}

local class, name, face, voice, listen_button, voice_links_to_face_checkbox, face_image_label_obj, bio, age_base, age_bonus, age_total,
level_base, level_bonus, level_total, exp, full_hp, current_hp, full_sp, current_sp, ac_base, ac_bonus, ac_total,
skill_points

function M.cleanup()
	class, name, face, voice, listen_button, voice_links_to_face_checkbox, face_image_label_obj, bio, age_base, age_bonus, age_total,
	level_base, level_bonus, level_total, exp, full_hp, current_hp, full_sp, current_sp, ac_base, ac_bonus, ac_total,
	skill_points = nil
end

local function update_face_image(face_index)
	local filename = facesound.get_good_cond_face_filename_by_index(face_index)
	face_image_label_obj:load_mm_bitmap_filename(filename, facesound.char_face_transparent_color)
end

local function link_face_and_voice(should_change_face)
	local checkbox_val = iup.GetAttribute(voice_links_to_face_checkbox, "VALUE")
	if checkbox_val == "ON" then
		local face_value = iup.GetInt(face, "VALUE") or 0
		local voice_value = iup.GetInt(voice, "VALUE") or 0
		if should_change_face then
			local face_should_be = voice_value
			if Merge ~= nil then
				if Game.CharacterPortraits[face_should_be].DefVoice ~= voice_value then
					for i = 0, Game.CharacterPortraits.Count - 1 do
						if Game.CharacterPortraits[i].DefVoice == voice_value then
							face_should_be = i
							break
						end
					end
				end
			end
			if face_value ~= face_should_be then
				iup.SetAttribute(face, "VALUE", face_should_be)
				update_face_image(face_should_be)
			end
		else
			local voice_should_be = face_value
			if Merge ~= nil then
				voice_should_be = Game.CharacterPortraits[face_value].DefVoice
			end
			if voice_value ~= voice_should_be then
				iup.SetAttribute(voice, "VALUE", voice_should_be)
			end
		end
	end
end

local function update_fields(char_index)
	local char = Party.PlayersArray[char_index]
	if char then
		-- Update basic stats fields
		iup.SetAttribute(name, "VALUE", enc.decode(char.Name) or "")
		local face_value = char.Face or 0
		iup.SetAttribute(face, "VALUE", face_value)
		update_face_image(face_value)
		if Game.Version ~= 6 then
			iup.SetAttribute(voice, "VALUE", char.Voice or 0)
		end
		if Game.Version == 8 then
			iup.SetAttribute(bio, "VALUE", enc.decode(char.Biography) or "")
		end
		iup.SetAttribute(age_base, "VALUE", char:GetBaseAge() or 20) -- OR Game.Year - char.BirthYear
		iup.SetAttribute(age_bonus, "VALUE", char.AgeBonus or 0)
		iup.SetAttribute(age_total, "VALUE", (char:GetBaseAge() or 20) + (char.AgeBonus or 0))
		iup.SetAttribute(level_base, "VALUE", char.LevelBase or 1)
		iup.SetAttribute(level_bonus, "VALUE", char.LevelBonus or 0)
		iup.SetAttribute(level_total, "VALUE", (char.LevelBase or 1) + (char.LevelBonus or 0))
		iup.SetAttribute(exp, "VALUE", char.Exp or 0)
		iup.SetAttribute(full_hp, "VALUE", char:GetFullHP() or 0)
		iup.SetAttribute(current_hp, "VALUE", char.HP or 0)
		iup.SetAttribute(full_sp, "VALUE", char:GetFullSP() or 0)
		iup.SetAttribute(current_sp, "VALUE", char.SP or 0)
		iup.SetAttribute(ac_base, "VALUE", char:GetBaseArmorClass() or 0)
		iup.SetAttribute(ac_bonus, "VALUE", char.ArmorClassBonus or 0)
		iup.SetAttribute(ac_total, "VALUE", (char:GetBaseArmorClass() or 0) + (char.ArmorClassBonus or 0))
		iup.SetAttribute(skill_points, "VALUE", char.SkillPoints or 0)

		-- Set class dropdown
		if char.Class then
			iup.SetAttribute(class, "VALUE", char.Class + 1)
		end
	end
end

-- function M.parent_firstload()
-- end

function M.parent_reload()
	-- if states.get_charsubtab_loaded(M) then -- always loaded
	update_fields(states.get_char_index())
	-- end
end

function M.parent_select_change()
	-- if states.get_charsubtab_loaded(M) then -- always loaded
	update_fields(states.get_char_index())
	-- end
end

function M.parent_apply()
	-- if states.get_charsubtab_loaded(M) then -- always loaded
	local char = Party.PlayersArray[states.get_char_index()]
	if char then
		-- Update character with new values
		local old_name = char.Name
		char.Name = enc.encode(iup.GetAttribute(name, "VALUE") or "")
		char.Face = iup.GetInt(face, "VALUE") or 0
		if Game.Version ~= 6 then
			char.Voice = iup.GetInt(voice, "VALUE") or 0
		end
		if Game.Version == 8 then
			char.Biography = enc.encode(iup.GetAttribute(bio, "VALUE") or "")
		end
		local old_levelbase = char.LevelBase
		char.LevelBase = iup.GetInt(level_base, "VALUE") or 1
		char.LevelBonus = iup.GetInt(level_bonus, "VALUE") or 0
		char.BirthYear = Game.Year - (iup.GetInt(age_base, "VALUE") or 20)
		char.AgeBonus = iup.GetInt(age_bonus, "VALUE") or 0
		char.Exp = iup.GetInt(exp, "VALUE") or 0
		char.HP = iup.GetInt(current_hp, "VALUE") or 0
		char.SP = iup.GetInt(current_sp, "VALUE") or 0
		char.ArmorClassBonus = iup.GetInt(ac_bonus, "VALUE") or 0
		char.SkillPoints = iup.GetInt(skill_points, "VALUE") or 0
		local old_class = char.Class
		char.Class = iup.GetInt(class, "VALUE") - 1
	end
	-- end
end

-- function M.reload()
-- end

function M.firstload()
	-- Create class list from const.Class and Game.ClassNames
	local class_names = {}
	local sorted_classes = {}
	for key, value in pairs(const.Class) do
		table.insert(sorted_classes, {
			key = key,
			value = value
		})
	end
	table.sort(sorted_classes, function(a, b)
		return a.value < b.value
	end)
	for _, item in ipairs(sorted_classes) do
		table.insert(class_names, enc.decode(Game.ClassNames[item.value]))
	end
	utils.load_select_options(class, class_names)

	if Game.Version ~= 6 then
		iup.SetAttribute(voice, "SPINMAX", facesound.get_face_count() - 1)
	end
	iup.SetAttribute(face, "SPINMAX", facesound.get_face_count() - 1)

	update_fields(states.get_char_index())
end

function M.create()
	name = ui.input("", {
		SIZE = "150x"
	})
	face = ui.uint_input("", {
		SIZE = "40x"
	})
	if Game.Version ~= 6 then
		voice = ui.uint_input("", {
			SIZE = "40x"
		})
	end
	listen_button = ui.button(i18n._("listen"))
	if Game.Version ~= 6 then
		voice_links_to_face_checkbox = ui.checkbox(i18n._("voice") .. " ↔ " .. i18n._("face"))
		iup.SetAttribute(voice_links_to_face_checkbox, "VALUE", "ON")
	end
	if Game.Version == 8 then
		bio = ui.multiline()
	end
	face_image_label_obj = ImageLabel:new({
		width = facesound.portrait_sizes.char.width,
		height = facesound.portrait_sizes.char.height
	})

	class = ui.select {}

	age_base = ui.int_input(20, {
		SIZE = "40x"
	})
	age_bonus = ui.int_input(0, {
		SIZE = "40x"
	})
	age_total = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})

	level_base = ui.uint_input(1, {
		SPINMIN = 1,
		SPINMAX = 10000,
		SIZE = "40x"
	})
	level_bonus = ui.int_input(0, {
		SIZE = "40x"
	})
	level_total = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	local set_exp_by_level_btn = ui.button(i18n._("level") .. " → " .. i18n._("exp"), nil, {
		TIP = i18n._("set_exp_by_level")
	})

	exp = ui.uint_input(0, {
		-- seemingly cannot be larger than 2147483647 due to IUP restriction
		SIZE = "80x"
	})
	local set_level_by_exp_btn = ui.button(i18n._("exp") .. " → " .. i18n._("level"), nil, {
		TIP = i18n._("set_level_by_exp")
	})

	-- Function to update total when base or bonus changes
	local function update_total(base_input, bonus_input, total_input, unsigned_total)
		if unsigned_total == nil then
			unsigned_total = false
		end
		local base = iup.GetInt(base_input, "VALUE") or 0
		local bonus = iup.GetInt(bonus_input, "VALUE") or 0
		local total = base + bonus
		if unsigned_total and total < 0 then
			total = 0
		end
		iup.SetAttribute(total_input, "VALUE", total)
	end

	iup.SetCallback(set_level_by_exp_btn, "ACTION", function()
		local exp_value = iup.GetInt(exp, "VALUE") or -1
		if exp_value >= 0 then
			local calculated_level = utils.exp_to_level(exp_value)
			iup.SetAttribute(level_base, "VALUE", calculated_level)
			update_total(level_base, level_bonus, level_total)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(set_exp_by_level_btn, "ACTION", function()
		local base_level = iup.GetInt(level_base, "VALUE") or -1
		if base_level >= 1 then
			local calculated_exp = utils.level_to_exp(base_level)
			iup.SetAttribute(exp, "VALUE", calculated_exp)
		end
		return iup.DEFAULT
	end)

	if Game.Version ~= 6 then
		iup.SetCallback(voice_links_to_face_checkbox, "VALUECHANGED_CB", function()
			link_face_and_voice()
			return iup.DEFAULT
		end)
	end

	iup.SetCallback(listen_button, "ACTION", function()
		local voice_value
		if Game.Version ~= 6 then
			voice_value = iup.GetInt(voice, "VALUE")
		else
			voice_value = iup.GetInt(face, "VALUE")
		end
		if voice_value then
			facesound.play_chooseme_sound_by_voice_index(voice_value)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(face, "VALUECHANGED_CB", function()
		local face_value = iup.GetInt(face, "VALUE")
		if face_value == nil or face_value < 0 then
			iup.SetAttribute(face, "VALUE", 0)
		elseif face_value >= facesound.get_face_count() then
			iup.SetAttribute(face, "VALUE", facesound.get_face_count() - 1)
		end

		if Game.Version ~= 6 then
			link_face_and_voice()
		end
		local face_index = iup.GetInt(face, "VALUE") or 0
		update_face_image(face_index)
		return iup.DEFAULT
	end)

	if Game.Version ~= 6 then
		iup.SetCallback(voice, "VALUECHANGED_CB", function()
			local voice_value = iup.GetInt(voice, "VALUE")
			if voice_value == nil or voice_value < 0 then
				iup.SetAttribute(voice, "VALUE", 0)
			elseif voice_value >= facesound.get_face_count() then
				iup.SetAttribute(voice, "VALUE", facesound.get_face_count() - 1)
			end

			link_face_and_voice(true)
			return iup.DEFAULT
		end)
	end

	current_hp = ui.int_input(0, {
		SIZE = "40x"
	})
	full_hp = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	local set_current_to_full_hp = ui.button(i18n._("current") .. " ← " .. i18n._("full"), nil, {
		TIP = i18n._("set_current_to_full_hp")
	})

	current_sp = ui.int_input(0, {
		SIZE = "40x"
	})
	full_sp = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	local set_current_to_full_sp = ui.button(i18n._("current") .. " ← " .. i18n._("full"), nil, {
		TIP = i18n._("set_current_to_full_sp")
	})
	ac_base = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	ac_bonus = ui.int_input(0, {
		SIZE = "40x"
	})
	ac_total = ui.input(0, {
		READONLY = "YES",
		SIZE = "40x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	skill_points = ui.uint_input(0, {
		SIZE = "40x"
	})

	local face_line = { face, face_image_label_obj.label }
	if Game.Version == 6 then
		table.insert(face_line, ui.vbox())
		table.insert(face_line, listen_button)
	end

	local voice_labelled_fields
	if Game.Version ~= 6 then
		voice_labelled_fields = ui.labelled_fields(i18n._("voice"),
			{ voice, listen_button, ui.vbox(), voice_links_to_face_checkbox }, 60)
	end

	-- Create frames for each group
	local basic_info_frame_content = { ui.labelled_fields(i18n._("name"), { name }, 60),
		ui.labelled_fields(i18n._("face"), face_line, 60)
	}
	if Game.Version ~= 6 then
		table.insert(basic_info_frame_content, voice_labelled_fields)
	end
	if Game.Version == 8 then
		table.insert(basic_info_frame_content, ui.labelled_fields(i18n._("bio"), { bio }, 60))
	end
	local basic_info_frame = ui.frame(i18n._("basic_info"), ui.vbox(basic_info_frame_content))

	local basic_stats_frame = ui.frame(i18n._("basic_stats"),
		ui.vbox({ ui.labelled_fields(i18n._("class"), { class }, nil, true),
			ui.labelled_fields(i18n._("age"),
				{ ui.label(i18n._("base")), age_base, ui.label(i18n._("bonus")), age_bonus, ui.label(i18n._("total")),
					age_total }, nil, true), ui.labelled_fields(i18n._("level"),
			{ ui.label(i18n._("base")), level_base, ui.label(i18n._("bonus")), level_bonus, ui.label(i18n._("total")),
				level_total, set_exp_by_level_btn }, nil, true),
			ui.labelled_fields(i18n._("experience"), { exp, set_level_by_exp_btn }, nil, true),
			ui.labelled_fields(i18n._("hit_points"),
				{ ui.label(i18n._("current")), current_hp, ui.label(i18n._("full")), full_hp, set_current_to_full_hp },
				nil,
				true), ui.labelled_fields(i18n._("spell_points"),
			{ ui.label(i18n._("current")), current_sp, ui.label(i18n._("full")), full_sp, set_current_to_full_sp }, nil,
			true),
			ui.labelled_fields(i18n._("armor_class"),
				{ ui.label(i18n._("base")), ac_base, ui.label(i18n._("bonus")), ac_bonus, ui.label(i18n._("total")),
					ac_total },
				nil, true), ui.labelled_fields(i18n._("skill_points"), { skill_points }, nil, true) }))

	-- Set up change handlers for all base/bonus inputs
	local function setup_total_update(base, bonus, total, unsigned_total)
		iup.SetCallback(base, "VALUECHANGED_CB", function()
			update_total(base, bonus, total, unsigned_total)
			return iup.DEFAULT
		end)
		iup.SetCallback(bonus, "VALUECHANGED_CB", function()
			update_total(base, bonus, total, unsigned_total)
			return iup.DEFAULT
		end)
	end

	-- Set up all total updates
	setup_total_update(age_base, age_bonus, age_total)
	setup_total_update(level_base, level_bonus, level_total)
	setup_total_update(ac_base, ac_bonus, ac_total, true)

	-- Set up HP/SP set to full callbacks
	iup.SetCallback(set_current_to_full_hp, "ACTION", function()
		local fullHP = iup.GetInt(full_hp, "VALUE") or 0
		iup.SetAttribute(current_hp, "VALUE", fullHP)
		return iup.DEFAULT
	end)

	iup.SetCallback(set_current_to_full_sp, "ACTION", function()
		local fullSP = iup.GetInt(full_sp, "VALUE") or 0
		iup.SetAttribute(current_sp, "VALUE", fullSP)
		return iup.DEFAULT
	end)

	return ui.hbox({ basic_info_frame, basic_stats_frame }, {
		TABTITLE = i18n._("basics"),
		ALIGNMENT = "ATOP"
	})
end

return M
