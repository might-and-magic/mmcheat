local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")
local enc = require("MMCheat/i18n/encoding")

local M = {}

local party_buff_caster

local function apply_full_hp_sp()
	for _, char in Party do
		local full_hp = char:GetFullHP()
		local full_sp = char:GetFullSP()
		if char.HP < full_hp then
			char.HP = full_hp
		end
		if char.SP < full_sp then
			char.SP = full_sp
		end
	end
	return iup.DEFAULT
end

local function apply_remove_negative_bonus_stats()
	for _, char in Party do
		-- Remove negative stat bonuses
		for _, stat in ipairs(utils.get_7stats()) do
			if char[stat .. "Bonus"] < 0 then
				char[stat .. "Bonus"] = 0
			end
		end

		-- Remove negative resistance bonuses
		for _, res in ipairs(utils.get_res()) do
			if char[res .. "ResistanceBonus"] < 0 then
				char[res .. "ResistanceBonus"] = 0
			end
		end

		-- Handle special cases
		if char.ArmorClassBonus < 0 then
			char.ArmorClassBonus = 0
		end
		if char.LevelBonus < 0 then
			char.LevelBonus = 0
		end
		-- AgeBonus is special: positive values are bad
		if char.AgeBonus > 0 then
			char.AgeBonus = 0
		end
	end
	return iup.DEFAULT
end

local function apply_good_condition()
	for _, char in Party do
		-- Remove all bad conditions
		for condition = 0, utils.mm6or78(16, 17) do
			char.Conditions[condition] = 0
		end
	end
	return iup.DEFAULT
end

local function apply_repair_items()
	for _, char in Party do
		for j = 1, char.Items.Count do
			local item = char.Items[j]
			if item and item.Number ~= 0 then
				item.Identified = true
				item.Broken = false
			end
		end
	end
	return iup.DEFAULT
end

local lock_timer_duration = const.Minute * 5
local lock_heal_fn = function()
	-- Game.ShowStatusText("Heal")
	apply_full_hp_sp()
	apply_remove_negative_bonus_stats()
	apply_good_condition()
	apply_repair_items()
end
local should_lock_heal = false
local lock_heal_handler_added = false

function M.cleanup()
	party_buff_caster = nil
end

function M.reload()
	local current_caster = iup.GetAttribute(party_buff_caster, "VALUE")
	utils.load_select_options(party_buff_caster, utils.get_char_name_array(true))
	iup.SetAttribute(party_buff_caster, "VALUE", current_caster)
end

function M.firstload()
	utils.load_select_options(party_buff_caster, utils.get_char_name_array(true))
	iup.SetAttribute(party_buff_caster, "VALUE", "1")
end

function M.create()
	-- Create input fields with default values
	local skills_level = ui.uint_input(60, {
		SPINMAX = 255
	})
	local skills_mastery = ui.select(utils.get_mastery_array(), utils.mm6or78(4, 5))
	local stats_value = ui.int_input(500)
	local resistances_value = ui.uint_input(100)
	local class_select
	if Game.Version ~= 6 then
		class_select = ui.select({ i18n._("random_path"), i18n._("light_path"), i18n._("dark_path") }, 1)
	end
	local level_value = ui.uint_input(utils.mmotherormerge(500, 50)) -- MMMerge's monster lv is set with player's, so player's shouldn't be too high
	local exp_value = ui.uint_input(utils.mmotherormerge(124750000, 1225000), {
		SIZE = "100x"
	})
	local skill_points_value = ui.uint_input(5000)
	local food_value = ui.uint_input(500, {
		SIZE = "80x"
	})
	local gold_value = ui.uint_input(5000000, {
		SIZE = "80x"
	})

	-- Add buff input fields
	local party_buff_days = ui.uint_input(365, {
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local party_buff_hours = ui.uint_input(0, {
		SPINMAX = 23,
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local party_buff_minutes = ui.uint_input(0, {
		SPINMAX = 59,
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local party_buff_power = ui.uint_input(100, {
		SIZE = "40x"
	})
	party_buff_caster = ui.select({})
	local party_buff_skill = ui.select(utils.get_mastery_array(), utils.mm6or78(4, 5))

	local char_buff_days = ui.uint_input(365, {
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local char_buff_hours = ui.uint_input(0, {
		SPINMAX = 23,
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local char_buff_minutes = ui.uint_input(0, {
		SPINMAX = 59,
		SIZE = "40x",
		ALIGNMENT = "ARIGHT"
	})
	local char_buff_power = ui.uint_input(100, {
		SIZE = "40x"
	})
	local char_buff_skill = ui.select(utils.get_mastery_array(), utils.mm6or78(4, 5))

	local mistform_local_name = utils.get_spell_local_name("Mistform")
	local char_buff_exclude_mistform_checkbox = ui.checkbox(i18n._("exclude_x", mistform_local_name))
	iup.SetAttribute(char_buff_exclude_mistform_checkbox, "VALUE", "ON")

	-- Add buff labels
	local party_buff_days_label = ui.label(i18n._("days_shortname"))
	local party_buff_hours_label = ui.label(i18n._("hours_shortname"))
	local party_buff_minutes_label = ui.label(i18n._("minutes_shortname"))
	local party_buff_power_label = ui.label(i18n._("power"))
	local party_buff_caster_label = ui.label(i18n._("caster"))
	local party_buff_skill_label = ui.label(i18n._("skill"))

	local char_buff_days_label = ui.label(i18n._("days_shortname"))
	local char_buff_hours_label = ui.label(i18n._("hours_shortname"))
	local char_buff_minutes_label = ui.label(i18n._("minutes_shortname"))
	local char_buff_power_label = ui.label(i18n._("power"))
	local char_buff_skill_label = ui.label(i18n._("skill"))

	-- Create buttons
	local stats_button = ui.button(i18n._("seven_stats"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local resistances_button = ui.button(i18n._("resistances"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local class_button = ui.button(i18n._("max_class"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local level_button = ui.button(i18n._("level"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local set_exp_by_level_btn = ui.button(i18n._("set_exp_by_level"), nil)
	local exp_button = ui.button(i18n._("experience"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local set_level_by_exp_btn = ui.button(i18n._("set_level_by_exp"), nil)
	local skill_points_button = ui.button(i18n._("skill_points"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local all_skills_button = ui.button(i18n._("all_skills"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local skills_select = ui.select({ i18n._("learnable_skills_max"), i18n._("learnable_skills_custom"),
		i18n._("all_skills_custom") }, 1, {
		EXPAND = "NO"
	})
	local skills_level_label = ui.label(i18n._("level"))
	local all_spells_button = ui.button(i18n._("all_spells"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local party_buffs_button = ui.button(i18n._("party_buffs"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local char_buffs_button = ui.button(i18n._("char_buffs"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local food_and_gold_button = ui.button(i18n._("food") .. i18n._("nn") .. i18n._("gold"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "80x"
	})
	local food_label = ui.label(i18n._("food"))
	local gold_label = ui.label(i18n._("gold"))
	local full_hp_sp_button = ui.button(i18n._("full_hp_sp"), nil, {
		FGCOLOR = ui.apply_button_color
	})
	local remove_stat_bonuses_button = ui.button(i18n._("remove_stat_bonuses"), nil, {
		FGCOLOR = ui.apply_button_color
	})
	local good_condition_button = ui.button(i18n._("good_condition"), nil, {
		FGCOLOR = ui.apply_button_color
	})
	local repair_items_button = ui.button(i18n._("repair_items"), nil, {
		FGCOLOR = ui.apply_button_color
	})
	local lock_checkbox = ui.checkbox(i18n._("lock") .. i18n._("colon"), nil, {
		RIGHTBUTTON = "YES",
		FGCOLOR = ui.onetime_change_label_color
	})
	iup.SetAttribute(lock_checkbox, "VALUE", should_lock_heal and "ON" or "OFF")
	local lock_button = ui.button(i18n._("ok"), nil, {
		FGCOLOR = ui.apply_button_color
	})
	local do_all_button = ui.button(i18n._("do_all"):upper(), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "100x",
		TITLE = i18n._("do_all"),
		TIP = i18n._("do_all_tip"),
		IMAGE = states.logo.handle_name
	})

	-- Callback functions
	local function apply_stats()
		local value = iup.GetInt(stats_value, "VALUE") or 0
		for _, char in Party do
			for _, stat in ipairs(utils.get_7stats()) do
				char[stat .. "Base"] = value
			end
		end
		return iup.DEFAULT
	end

	local function apply_resistances()
		local value = iup.GetInt(resistances_value, "VALUE") or 0
		for _, char in Party do
			for _, res in ipairs(utils.get_res()) do
				char[res .. "ResistanceBase"] = value
			end
		end
		return iup.DEFAULT
	end

	local function apply_class()
		local class_value
		if Game.Version == 6 then
			class_value = "2"
		else
			class_value = iup.GetAttribute(class_select, "VALUE")
		end
		for _, char in Party do
			local is_dark = false
			if class_value == "3" then -- dark
				is_dark = true
			elseif class_value == "1" then -- random
				is_dark = math.random() < 0.5
			end
			char.Class = utils.max_class(char.Class, is_dark) or char.Class
		end
		return iup.DEFAULT
	end

	local function apply_level()
		local level = iup.GetInt(level_value, "VALUE") or 1
		for _, char in Party do
			char.LevelBase = level
			char.LevelBonus = 0
		end
		return iup.DEFAULT
	end

	local function apply_set_exp_by_level()
		local level = iup.GetInt(level_value, "VALUE") or 1
		local exp = utils.level_to_exp(level)
		iup.SetAttribute(exp_value, "VALUE", exp)
		return iup.DEFAULT
	end

	local function apply_exp()
		local exp = iup.GetInt(exp_value, "VALUE") or 0
		for _, char in Party do
			char.Exp = exp
		end
		return iup.DEFAULT
	end

	local function apply_set_level_by_exp()
		local exp = iup.GetInt(exp_value, "VALUE") or 0
		local level = utils.exp_to_level(exp)
		iup.SetAttribute(level_value, "VALUE", level)
		return iup.DEFAULT
	end

	local function apply_skill_points()
		local points = iup.GetInt(skill_points_value, "VALUE") or 0
		for _, char in Party do
			char.SkillPoints = points
		end
		return iup.DEFAULT
	end

	local function apply_all_skills()
		local level = iup.GetInt(skills_level, "VALUE") or 1
		local mastery_value = iup.GetInt(skills_mastery, "VALUE") or 2
		local mastery = mastery_value - 1
		local skills_option = iup.GetAttribute(skills_select, "VALUE")

		for _, char in Party do
			if skills_option == "1" or skills_option == "2" then
				local available_skills = {}
				for skill_id, reachable_mastery in EnumAvailableSkills(char.Class) do
					available_skills[skill_id] = reachable_mastery
				end
				-- Process all skills
				for i = 0, char.Skills.Count - 1 do
					local reachable_mastery = available_skills[i]
					if reachable_mastery then
						local target_mastery
						if skills_option == "1" then -- "Learnable skills, max reachable mastery, custom level"
							target_mastery = reachable_mastery
						else       -- "Learnable skills, custom mastery & level"
							target_mastery = mastery
						end
						char.Skills[i] = JoinSkill(level, target_mastery)
					else
						char.Skills[i] = 0 -- Remove skill if not available for class
					end
				end
			else -- "All skills, custom mastery & level"
				for i = 0, char.Skills.Count - 1 do
					char.Skills[i] = JoinSkill(level, mastery)
				end
			end
		end
		return iup.DEFAULT
	end

	local function apply_all_spells()
		for _, char in Party do
			for spell_index = 1, char.Spells.Count do
				char.Spells[spell_index] = true
			end
		end
		return iup.DEFAULT
	end

	local function apply_party_buffs()
		-- Set all party buffs with values from input fields
		local current_time = Game.Time
		local days_val = iup.GetInt(party_buff_days, "VALUE") or 0
		local hours_val = iup.GetInt(party_buff_hours, "VALUE") or 0
		local minutes_val = iup.GetInt(party_buff_minutes, "VALUE") or 0
		local power_val = iup.GetInt(party_buff_power, "VALUE") or 0
		local caster_val = iup.GetInt(party_buff_caster, "VALUE") or 1
		local skill_val = iup.GetInt(party_buff_skill, "VALUE") or 1

		local expire_time = current_time + utils.time_to_timestamp(0, 0, days_val, hours_val, minutes_val, 0, true)

		for _, buff_index in pairs(const.PartyBuff) do
			local buff = Party.SpellBuffs[buff_index]
			if buff then
				buff.Bits = 1 -- Enable buff
				buff.ExpireTime = expire_time
				buff.Power = power_val
				buff.Caster = caster_val - 1 -- Subtract 1 because "Empty" is the first option
				buff.Skill = skill_val - 1 -- Subtract 1 because "Not learned" is the first option
			end
		end
		return iup.DEFAULT
	end

	local function apply_char_buffs()
		-- Set all character buffs with values from input fields
		local current_time = Game.Time
		local days_val = iup.GetInt(char_buff_days, "VALUE") or 0
		local hours_val = iup.GetInt(char_buff_hours, "VALUE") or 0
		local minutes_val = iup.GetInt(char_buff_minutes, "VALUE") or 0
		local power_val = iup.GetInt(char_buff_power, "VALUE") or 0
		local skill_val = iup.GetInt(char_buff_skill, "VALUE") or 1
		local exclude_mistform_val = iup.GetAttribute(char_buff_exclude_mistform_checkbox, "VALUE") or "ON"

		local expire_time = current_time + utils.time_to_timestamp(0, 0, days_val, hours_val, minutes_val, 0, true)

		for _, char in Party do
			for _, buff_index in pairs(const.PlayerBuff) do
				local buff = char.SpellBuffs[buff_index]
				if buff and not (exclude_mistform_val == "ON" and buff_index == 26) then -- 26 is const.PlayerBuff.Misform (typo in this const and not sure if it'll be fixed in future so hardcoded as number here)
					buff.Bits = 1                                            -- Enable buff
					buff.ExpireTime = expire_time
					buff.Power = power_val
					buff.Skill = skill_val - 1 -- Subtract 1 because "Not learned" is the first option
				end
			end
		end
		return iup.DEFAULT
	end

	local function apply_food_and_gold()
		local food_value = iup.GetInt(food_value, "VALUE") or 0
		local gold_value = iup.GetInt(gold_value, "VALUE") or 0
		Party.Food = food_value
		Party.Gold = gold_value
		return iup.DEFAULT
	end

	local function apply_heal_lock()
		local lock_val = iup.GetAttribute(lock_checkbox, "VALUE") or "OFF"
		if lock_val == "ON" and not should_lock_heal then
			lock_heal_fn()
			Timer(lock_heal_fn, lock_timer_duration)
			should_lock_heal = true
			if not lock_heal_handler_added then
				---@diagnostic disable-next-line: duplicate-set-field
				function events.AfterLoadMap()
					if should_lock_heal then
						lock_heal_fn()
						Timer(lock_heal_fn, lock_timer_duration)
					end
				end

				---@diagnostic disable-next-line: duplicate-set-field
				function events.LeaveGame()
					if should_lock_heal then
						RemoveTimer(lock_heal_fn)
						should_lock_heal = false
					end
				end

				---@diagnostic disable-next-line: duplicate-set-field
				function events.CalcDamageToPlayer(t)
					if should_lock_heal then
						t.Result = 0
					end
				end

				---@diagnostic disable-next-line: duplicate-set-field
				function events.DoBadThingToPlayer(t)
					if should_lock_heal then
						t.Allow = false
					end
				end

				lock_heal_handler_added = true
			end
		end

		if lock_val == "OFF" and should_lock_heal then
			RemoveTimer(lock_heal_fn)
			should_lock_heal = false
		end
		return iup.DEFAULT
	end

	local function apply_all()
		-- Note: must be in correct order
		apply_stats()
		apply_resistances()
		apply_class()
		apply_level()
		apply_exp()
		apply_skill_points()
		apply_all_skills()
		apply_all_spells()
		apply_party_buffs()
		apply_char_buffs()
		apply_food_and_gold()
		apply_full_hp_sp()
		apply_remove_negative_bonus_stats()
		apply_good_condition()
		apply_repair_items()
		apply_heal_lock()
		return iup.DEFAULT
	end

	local function on_skills_select_change(self)
		local value = iup.GetAttribute(self, "VALUE")
		if value == "1" then -- "Learnable skills, max reachable mastery, custom level"
			iup.SetAttribute(skills_mastery, "ACTIVE", "NO")
		else           -- "Learnable skills, custom mastery & level" or "All skills, custom mastery & level"
			iup.SetAttribute(skills_mastery, "ACTIVE", "YES")
		end
		return iup.DEFAULT
	end

	-- Set callbacks
	iup.SetCallback(all_skills_button, "ACTION", apply_all_skills)
	iup.SetCallback(all_spells_button, "ACTION", apply_all_spells)
	iup.SetCallback(stats_button, "ACTION", apply_stats)
	iup.SetCallback(resistances_button, "ACTION", apply_resistances)
	iup.SetCallback(class_button, "ACTION", apply_class)
	iup.SetCallback(level_button, "ACTION", apply_level)
	iup.SetCallback(set_exp_by_level_btn, "ACTION", apply_set_exp_by_level)
	iup.SetCallback(exp_button, "ACTION", apply_exp)
	iup.SetCallback(set_level_by_exp_btn, "ACTION", apply_set_level_by_exp)
	iup.SetCallback(skill_points_button, "ACTION", apply_skill_points)
	iup.SetCallback(party_buffs_button, "ACTION", apply_party_buffs)
	iup.SetCallback(char_buffs_button, "ACTION", apply_char_buffs)
	iup.SetCallback(food_and_gold_button, "ACTION", apply_food_and_gold)
	iup.SetCallback(full_hp_sp_button, "ACTION", apply_full_hp_sp)
	iup.SetCallback(remove_stat_bonuses_button, "ACTION", apply_remove_negative_bonus_stats)
	iup.SetCallback(good_condition_button, "ACTION", apply_good_condition)
	iup.SetCallback(repair_items_button, "ACTION", apply_repair_items)
	iup.SetCallback(lock_button, "ACTION", apply_heal_lock)
	iup.SetCallback(do_all_button, "ACTION", apply_all)
	iup.SetCallback(skills_select, "VALUECHANGED_CB", on_skills_select_change)

	-- Initialize mastery state based on default selection
	iup.SetAttribute(skills_mastery, "ACTIVE", "NO")

	local char_buffs_line = { char_buffs_button, char_buff_days, char_buff_days_label, char_buff_hours,
		char_buff_hours_label,
		char_buff_minutes, char_buff_minutes_label, char_buff_power_label, char_buff_power,
		char_buff_skill_label,
		char_buff_skill }
	if Game.Version == 8 then
		table.insert(char_buffs_line, char_buff_exclude_mistform_checkbox)
	end

	-- Create layout
	local god_mode_frame = ui.frame(i18n._("god_mode"),
		ui.vbox({ ui.hbox({ all_spells_button, ui.centered_vbox({ ui.label(i18n._("god_mode_for_all_in_party"), {
			PADDING = "25x0"
		}) }, {
			ALIGNMENT = "ARIGHT"
		}) }), ui.hbox({
			stats_button, stats_value }),
			ui.hbox({ resistances_button, resistances_value }),
			ui.hbox(utils.mm6or78({ class_button }, { class_button, class_select })),
			ui.hbox({ level_button, level_value, set_exp_by_level_btn }),
			ui.hbox({ exp_button, exp_value, set_level_by_exp_btn }),
			ui.hbox({ skill_points_button, skill_points_value }),
			ui.hbox({ all_skills_button, skills_select, skills_level_label, skills_level, skills_mastery }),
			ui.hbox(
				{ party_buffs_button, party_buff_days, party_buff_days_label, party_buff_hours, party_buff_hours_label,
					party_buff_minutes, party_buff_minutes_label, party_buff_power_label, party_buff_power,
					party_buff_caster_label, party_buff_caster, party_buff_skill_label, party_buff_skill }),
			ui.hbox(char_buffs_line), ui.hbox({ food_and_gold_button, food_label, food_value, gold_label, gold_value }) }))

	local heal_frame = ui.frame(i18n._("heal"),
		ui.button_hbox({ full_hp_sp_button, remove_stat_bonuses_button, good_condition_button,
			repair_items_button, ui.vbox(), lock_checkbox, lock_button }))

	return ui.vbox({ god_mode_frame, heal_frame, ui.hbox(do_all_button) }, {
		TABTITLE = i18n._("god_mode"),
		ALIGNMENT = "ACENTER"
	})
end

return M
