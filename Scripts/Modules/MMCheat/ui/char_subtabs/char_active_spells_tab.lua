local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")

local M = {}

local spell_list, days, hours, minutes, power, skill, apply_button, remove_button
local sorted_buffs

function M.cleanup()
	spell_list, days, hours, minutes, power, skill, apply_button, remove_button = nil
	sorted_buffs = nil
end

-- Function to reset all inputs
local function reset_inputs()
	iup.SetAttribute(spell_list, "VALUE", "0") -- Default to non-selected
	iup.SetAttribute(skill, "VALUE", "1")   -- Default to "Not learned"
	iup.SetAttribute(days, "VALUE", "0")
	iup.SetAttribute(hours, "VALUE", "0")
	iup.SetAttribute(minutes, "VALUE", "0")
	iup.SetAttribute(power, "VALUE", "0")
end

local function reload_spell_list_options(char_index)
	-- Sort const.PlayerBuff by value
	sorted_buffs = {}
	for _, buff_index in pairs(const.PlayerBuff) do
		local name = utils.const_to_globaltxt("PlayerBuff", buff_index)
		local char = Party.PlayersArray[char_index]
		local buff = char.SpellBuffs[buff_index]
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

-- function M.parent_firstload()
-- end

function M.parent_reload()
	if states.get_charsubtab_loaded(M) then
		reload_spell_list_options(states.get_char_index())
		reset_inputs()
	end
end

function M.parent_select_change()
	if states.get_charsubtab_loaded(M) then
		reload_spell_list_options(states.get_char_index())
		reset_inputs()
	end
end

-- function M.parent_apply()
-- end

-- function M.reload()
-- end

function M.firstload()
	reload_spell_list_options(states.get_char_index())

	utils.load_select_options(skill, utils.get_mastery_array())

	-- Set callback for spell list selection
	iup.SetCallback(spell_list, "VALUECHANGED_CB", function()
		local selected_index = iup.GetInt(spell_list, "VALUE")
		if selected_index then
			local buff_data = sorted_buffs[selected_index]
			if buff_data then
				local buff_index = buff_data.index
				if buff_index then
					if Party and Party.PlayersArray and Party.PlayersArray[states.get_char_index()] then
						local char = Party.PlayersArray[states.get_char_index()]

						if not char then
							return iup.DEFAULT
						end

						local buff = char.SpellBuffs[buff_index]
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

						-- Update skill (add 1 because "Not learned" is the first option)
						iup.SetAttribute(skill, "VALUE", tostring(buff.Skill + 1))
					end
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
					if Party and Party.PlayersArray and Party.PlayersArray[states.get_char_index()] then
						local char = Party.PlayersArray[states.get_char_index()]
						local buff = char.SpellBuffs[buff_index]

						-- Get input values
						local days_val = iup.GetInt(days, "VALUE") or 0
						local hours_val = iup.GetInt(hours, "VALUE") or 0
						local minutes_val = iup.GetInt(minutes, "VALUE") or 0
						local power_val = iup.GetInt(power, "VALUE") or 0
						local skill_val = iup.GetInt(skill, "VALUE") or 1

						-- Calculate expire time
						local current_time = Game.Time
						local expire_time = current_time +
							utils.time_to_timestamp(0, 0, days_val, hours_val, minutes_val, 0, true)

						-- Update buff
						buff.ExpireTime = expire_time
						buff.Power = power_val
						buff.Skill = skill_val - 1 -- Subtract 1 because "Not learned" is the first option

						reload_spell_list_options(states.get_char_index())

						iup.SetAttribute(spell_list, "VALUE", tostring(selected_index))
					end
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
					if Party and Party.PlayersArray and Party.PlayersArray[states.get_char_index()] then
						local char = Party.PlayersArray[states.get_char_index()]
						local buff = char.SpellBuffs[buff_index]

						-- Reset buff
						buff.Bits = 0
						buff.Caster = 0
						buff.ExpireTime = 0
						buff.OverlayId = 0
						buff.Power = 0
						buff.Skill = 0

						-- Reset inputs
						reset_inputs()

						reload_spell_list_options(states.get_char_index())

						iup.SetAttribute(spell_list, "VALUE", tostring(selected_index))
					end
				end
			end
		end
		return iup.DEFAULT
	end)

	reset_inputs()
end

function M.create()
	spell_list = ui.list({}, nil, {
		SIZE = "120x250"
	})

	days = ui.uint_input(0, {
		SIZE = "40x"
	})
	hours = ui.uint_input(0, {
		SPINMAX = 23,
		SIZE = "40x"
	})
	minutes = ui.uint_input(0, {
		SPINMAX = 59,
		SIZE = "40x"
	})
	power = ui.uint_input(0, {
		SIZE = "40x"
	})
	skill = ui.select {}

	apply_button = ui.button(i18n._("apply"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	remove_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})

	return ui.hbox({ spell_list,
		ui.vbox(
			{ ui.vbox({ ui.labelled_fields(i18n._("days"), { days }, 60), ui.labelled_fields(i18n._("hours"), { hours },
				60),
				ui.labelled_fields(i18n._("minutes"), { minutes }, 60),
				ui.labelled_fields(i18n._("power"), { power }, 60), ui.labelled_fields(i18n._("skill"), { skill }, 60) }),
				ui.button_hbox({ apply_button, remove_button }) }, {
				ALIGNMENT = "ACENTER"
			}) }, {
		TABTITLE = i18n._("active_spells"),
		ALIGNMENT = "ACENTER"
	})
end

return M
