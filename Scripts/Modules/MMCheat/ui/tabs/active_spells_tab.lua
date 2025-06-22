local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")

local M = {}

local cast_spell_select, cast_spell_level, cast_spell_mastery, cast_spell_button
local spell_list, days, hours, minutes, power, caster, skill, apply_button, remove_button
local sorted_buffs
local divine_checkbox, armageddon_checkbox, unlimited_daily_cast_ok_button

function M.cleanup()
	cast_spell_select, cast_spell_level, cast_spell_mastery, cast_spell_button = nil
	spell_list, days, hours, minutes, power, caster, skill, apply_button, remove_button = nil
	sorted_buffs = nil
	divine_checkbox, armageddon_checkbox, unlimited_daily_cast_ok_button = nil
end

local use_armageddon = false
local armageddon_handler_added = false
local use_divine = false
local divine_handler_added = false

local function apply_divine()
	local divine_val = iup.GetAttribute(divine_checkbox, "VALUE") or "OFF"
	if divine_val == "ON" and not use_divine then
		for _, char in Party do
			if char.DevineInterventionCasts and char.DevineInterventionCasts > 0 then
				char.DevineInterventionCasts = 0
			end
		end
		use_divine = true
		if not divine_handler_added then
			---@diagnostic disable-next-line: duplicate-set-field
			function events.LeaveGame()
				if use_divine then
					use_divine = false
				end
			end

			---@diagnostic disable-next-line: duplicate-set-field
			function events.PlaySound(t)
				if use_divine then
					if t.Sound == 17100 then -- 17100 is sound of Devine Intervention spell for all 6/7/8
						for _, char in Party do
							if char.DevineInterventionCasts and char.DevineInterventionCasts > 0 then
								char.DevineInterventionCasts = 0
							end
						end
					end
				end
			end

			divine_handler_added = true
		end
	end
	if divine_val == "OFF" and use_divine then
		use_divine = false
	end
	return iup.DEFAULT
end

local function apply_armageddon()
	local armageddon_val = iup.GetAttribute(armageddon_checkbox, "VALUE") or "OFF"
	if armageddon_val == "ON" and not use_armageddon then
		for _, char in Party do
			if char.ArmageddonCasts and char.ArmageddonCasts > 0 then
				char.ArmageddonCasts = 0
			end
		end
		use_armageddon = true
		if not armageddon_handler_added then
			---@diagnostic disable-next-line: duplicate-set-field
			function events.LeaveGame()
				if use_armageddon then
					use_armageddon = false
				end
			end

			---@diagnostic disable-next-line: duplicate-set-field
			function events.CalcDamageToPlayer(t)
				if use_armageddon then
					if t.DamageKind == utils.mmotherormerge(const.Damage.Magic, const.Damage.Dark) and t.Player and t.Player.ArmageddonCasts and t.Player.ArmageddonCasts > 0 then
						t.Player.ArmageddonCasts = 0
					end
				end
			end

			armageddon_handler_added = true
		end
	end
	if armageddon_val == "OFF" and use_armageddon then
		use_armageddon = false
	end
end

local function load_casters()
	utils.load_select_options(caster, utils.get_char_name_array(true))
end

-- Function to reset all inputs
local function reset_inputs()
	iup.SetAttribute(spell_list, "VALUE", "0") -- Default to non-selected
	iup.SetAttribute(caster, "VALUE", "1")  -- Default to "[Empty]"
	iup.SetAttribute(skill, "VALUE", "1")   -- Default to "Not learned"
	iup.SetAttribute(days, "VALUE", "0")
	iup.SetAttribute(hours, "VALUE", "0")
	iup.SetAttribute(minutes, "VALUE", "0")
	iup.SetAttribute(power, "VALUE", "0")
end

local function reload_spell_list_options()
	-- Sort const.PartyBuff by value
	sorted_buffs = {}
	for _, buff_index in pairs(const.PartyBuff) do
		local name = utils.const_to_globaltxt("PartyBuff", buff_index)
		local buff = Party.SpellBuffs[buff_index]
		local active = buff.ExpireTime ~= 0 and buff.ExpireTime > Game.Time
		table.insert(sorted_buffs, {
			name = name,
			index = buff_index,
			active = active
		})
	end
	table.sort(sorted_buffs, function(a, b)
		return a.index < b.index
	end)
	local sorted_buff_names = {}
	for i, v in ipairs(sorted_buffs) do
		table.insert(sorted_buff_names, (v.active and "✓ " or "    ") .. v.name)
	end

	utils.load_select_options(spell_list, sorted_buff_names, true)
end

function M.reload()
	-- Reload because name and other info could change
	load_casters()
	reload_spell_list_options()
	reset_inputs()
end

function M.firstload()
	-- CAST SPELL (mm8 only)
	if Game.Version == 8 then
		-- Initialize spell list for cast_spell_select
		local spell_names = {}
		local spell_indexes = {}
		for i = 1, Game.SpellsTxt.Count - 1 do
			if Game.SpellsTxt[i].ShortName ~= '0' then
				spell_names[#spell_names + 1] = enc.decode(Game.SpellsTxt[i].Name)
				spell_indexes[#spell_names] = i
			end
		end

		-- Set spell select options
		iup.SetAttribute(cast_spell_select, "COUNT", tostring(#spell_names))
		for i, name in ipairs(spell_names) do
			iup.SetAttribute(cast_spell_select, tostring(i), name)
		end
		iup.SetAttribute(cast_spell_select, "VALUE", "1")

		-- Set callbacks for level and mastery interaction
		iup.SetCallback(cast_spell_level, "VALUECHANGED_CB", function()
			local value = iup.GetInt(cast_spell_level, "VALUE") or 1
			if value < 1 then
				iup.SetAttribute(cast_spell_level, "VALUE", "1")
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(cast_spell_mastery, "VALUECHANGED_CB", function()
			local value = iup.GetInt(cast_spell_mastery, "VALUE") or 1
			if value < 1 then
				iup.SetAttribute(cast_spell_mastery, "VALUE", "1")
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(cast_spell_button, "ACTION", function()
			local selected_index = iup.GetInt(cast_spell_select, "VALUE")
			if selected_index then
				local spell_id = spell_indexes[selected_index]
				local level = iup.GetInt(cast_spell_level, "VALUE") or 1
				local mastery = iup.GetInt(cast_spell_mastery, "VALUE") or 1

				if spell_id then
					utils.CastSpellDirect(spell_id, level, mastery)
					return iup.CLOSE
				end
			end
		end)
	end

	-- ACTIVE SPELLS (PARTY BUFF)
	reload_spell_list_options()

	utils.load_select_options(skill, utils.get_mastery_array())

	load_casters()
	reset_inputs()

	-- Set callback for spell list selection
	iup.SetCallback(spell_list, "VALUECHANGED_CB", function()
		local selected_index = iup.GetInt(spell_list, "VALUE")
		if selected_index then
			local buff_data = sorted_buffs[selected_index]
			if buff_data then
				local buff_index = buff_data.index
				if buff_index then
					local buff = Party.SpellBuffs[buff_index]
					if not buff then
						return iup.DEFAULT
					end

					-- Calculate time left
					local current_time = Game.Time
					local time_diff = buff.ExpireTime - current_time
					local time_left
					if time_diff <= 0 then
						time_left = {
							days = 0,
							hours = 0,
							minutes = 0
						}
					else
						time_left = utils.timestamp_to_time(buff.ExpireTime - current_time, true)
					end

					-- Update inputs
					iup.SetAttribute(days, "VALUE", tostring(time_left.days))
					iup.SetAttribute(hours, "VALUE", tostring(time_left.hours))
					iup.SetAttribute(minutes, "VALUE", tostring(time_left.minutes))
					iup.SetAttribute(power, "VALUE", tostring(buff.Power))

					-- Update caster
					iup.SetAttribute(caster, "VALUE", tostring(buff.Caster + 1))

					-- Update skill (add 1 because "Not learned" is the first option)
					iup.SetAttribute(skill, "VALUE", tostring(buff.Skill + 1))
				end
			end
		end
		return iup.DEFAULT
	end)

	-- Set callback for apply button
	iup.SetCallback(apply_button, "ACTION", function()
		local selected_index = iup.GetInt(spell_list, "VALUE")
		if selected_index then
			local buff_data = sorted_buffs[selected_index]
			if buff_data then
				local buff_index = buff_data.index
				if buff_index then
					local buff = Party.SpellBuffs[buff_index]

					-- Get input values
					local days_val = iup.GetInt(days, "VALUE") or 0
					local hours_val = iup.GetInt(hours, "VALUE") or 0
					local minutes_val = iup.GetInt(minutes, "VALUE") or 0
					local power_val = iup.GetInt(power, "VALUE") or 0
					local caster_val = iup.GetInt(caster, "VALUE") or 1
					local skill_val = iup.GetInt(skill, "VALUE") or 1

					-- Calculate expire time
					local current_time = Game.Time
					local expire_time = current_time +
						utils.time_to_timestamp(0, 0, days_val, hours_val, minutes_val, 0, true)

					-- Update buff
					buff.ExpireTime = expire_time
					buff.Power = power_val
					buff.Caster = caster_val - 1 -- Subtract 1 because "Empty" is the first option
					buff.Skill = skill_val - 1 -- Subtract 1 because "Not learned" is the first option

					reload_spell_list_options()

					iup.SetAttribute(spell_list, "VALUE", tostring(selected_index))
				end
			end
		end
		return iup.DEFAULT
	end)

	-- Set callback for remove button
	iup.SetCallback(remove_button, "ACTION", function()
		local selected_index = iup.GetInt(spell_list, "VALUE")
		if selected_index then
			local buff_data = sorted_buffs[selected_index]
			if buff_data then
				local buff_index = buff_data.index
				if buff_index then
					local buff = Party.SpellBuffs[buff_index]

					-- Reset buff
					buff.Bits = 0
					buff.Caster = 0
					buff.ExpireTime = 0
					buff.OverlayId = 0
					buff.Power = 0
					buff.Skill = 0

					-- Reset inputs
					reset_inputs()

					reload_spell_list_options()

					iup.SetAttribute(spell_list, "VALUE", tostring(selected_index))
				end
			end
		end
		return iup.DEFAULT
	end)

	iup.SetAttribute(armageddon_checkbox, "VALUE", use_armageddon and "ON" or "OFF")
	iup.SetAttribute(divine_checkbox, "VALUE", use_divine and "ON" or "OFF")

	iup.SetCallback(unlimited_daily_cast_ok_button, "ACTION", function()
		apply_armageddon()
		apply_divine()
		return iup.DEFAULT
	end)
end

function M.create()
	-- Create CAST SPELL frame (MM8/Merge-only)
	local cast_spell_frame
	if Game.Version == 8 then
		cast_spell_select = ui.select {}

		local level_label = ui.label(i18n._("level"))
		cast_spell_level = ui.uint_input(60, {
			SPINMAX = 255,
			SPINMIN = 1,
			SIZE = "40x"
		})
		cast_spell_mastery = ui.select(utils.get_mastery_array(true), 4)
		cast_spell_button = ui.button(i18n._("ok"), nil, {
			MINSIZE = "80x",
			FGCOLOR = ui.apply_exit_button_color
		})

		cast_spell_frame = ui.frame(i18n._("cast_any_spell"), ui.hbox(
			{ cast_spell_select, level_label, cast_spell_level, cast_spell_mastery, cast_spell_button }))
	end

	-- ACTIVE SPELLS (PARTY BUFF)
	spell_list = ui.list({}, nil, {
		SIZE = "120x200"
	})

	days = ui.int_input(0)
	hours = ui.int_input(0, {
		SPINMAX = 23
	})
	minutes = ui.int_input(0, {
		SPINMAX = 59
	})
	power = ui.int_input(0)

	caster = ui.select {}
	skill = ui.select {}

	apply_button = ui.button(i18n._("apply"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	remove_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})

	local party_buff_frame = ui.frame(i18n._("party_buff_spells"), ui.hbox({ spell_list,
		ui.vbox(
			{ ui.vbox({ ui.labelled_fields(i18n._("days"), { days }, 60), ui.labelled_fields(i18n._("hours"), { hours },
				60),
				ui.labelled_fields(i18n._("minutes"), { minutes }, 60),
				ui.labelled_fields(i18n._("power"), { power }, 60), ui.labelled_fields(i18n._("caster"), { caster }, 60),
				ui.labelled_fields(i18n._("skill"), { skill }, 60) }), ui.button_hbox({ apply_button, remove_button }) },
			{
				ALIGNMENT = "ACENTER"
			}) }))

	local armageddon_local_name = utils.get_spell_local_name("Armageddon")
	local divine_intervention_local_name = utils.get_spell_local_name("DivineIntervention")
	armageddon_checkbox = ui.checkbox(armageddon_local_name, nil, {
		FGCOLOR = ui.onetime_change_label_color
	})
	divine_checkbox = ui.checkbox(divine_intervention_local_name, nil, {
		FGCOLOR = ui.onetime_change_label_color
	})

	unlimited_daily_cast_ok_button = ui.button(i18n._("ok"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	local unlimited_daily_cast_frame = ui.frame(i18n._("unlimited_daily_cast"),
		ui.hbox({ armageddon_checkbox, divine_checkbox, unlimited_daily_cast_ok_button }))

	local frames = {}
	if Game.Version == 8 then
		table.insert(frames, cast_spell_frame)
		table.insert(frames, ui.hbox())
	end
	table.insert(frames, party_buff_frame)
	table.insert(frames, ui.hbox())
	table.insert(frames, unlimited_daily_cast_frame)
	return ui.vbox(frames, {
		TABTITLE = i18n._("spells"),
		ALIGNMENT = "ACENTER"
	})
end

return M
