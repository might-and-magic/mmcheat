local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")

local M = {}

local inputs

function M.cleanup()
	inputs = nil
end

local function update_fields(char_index)
	local char = Party.PlayersArray[char_index]
	if char then
		-- Update condition times
		local function update_condition_time(index)
			local condition_time = char.Conditions[index]
			local has_condition = condition_time ~= 0
			iup.SetAttribute(inputs["checkbox_" .. index], "VALUE", has_condition and "ON" or "OFF")
			if has_condition then
				local ticks_elapsed = Game.Time - condition_time
				if ticks_elapsed > 0 then
					local total_minutes = math.floor(ticks_elapsed / const.Minute)
					local days = math.floor(total_minutes / (24 * 60))
					local remaining_minutes = total_minutes % (24 * 60)
					local hours = math.floor(remaining_minutes / 60)
					local minutes = remaining_minutes % 60
					iup.SetAttribute(inputs["days_" .. index], "VALUE", days)
					iup.SetAttribute(inputs["hours_" .. index], "VALUE", hours)
					iup.SetAttribute(inputs["minutes_" .. index], "VALUE", minutes)
				else
					iup.SetAttribute(inputs["days_" .. index], "VALUE", 0)
					iup.SetAttribute(inputs["hours_" .. index], "VALUE", 0)
					iup.SetAttribute(inputs["minutes_" .. index], "VALUE", 0)
				end
			else
				iup.SetAttribute(inputs["days_" .. index], "VALUE", 0)
				iup.SetAttribute(inputs["hours_" .. index], "VALUE", 0)
				iup.SetAttribute(inputs["minutes_" .. index], "VALUE", 0)
			end
		end

		for i = 0, 16 do
			update_condition_time(i)
		end
		if Game.Version ~= 6 then
			update_condition_time(17)
		end
	end
end

-- function M.parent_firstload()
-- end

function M.parent_reload()
	if states.get_charsubtab_loaded(M) then
		update_fields(states.get_char_index())
	end
end

function M.parent_select_change()
	if states.get_charsubtab_loaded(M) then
		update_fields(states.get_char_index())
	end
end

function M.parent_apply()
	if states.get_charsubtab_loaded(M) then
		local char = Party.PlayersArray[states.get_char_index()]
		if char then
			-- Update conditions
			local function update_condition(index)
				local is_checked = iup.GetAttribute(inputs["checkbox_" .. index], "VALUE") == "ON"
				if is_checked then
					local days = iup.GetInt(inputs["days_" .. index], "VALUE") or 0
					local hours = iup.GetInt(inputs["hours_" .. index], "VALUE") or 0
					local minutes = iup.GetInt(inputs["minutes_" .. index], "VALUE") or 0
					local total_minutes = days * 24 * 60 + hours * 60 + minutes
					char.Conditions[index] = Game.Time - (total_minutes * const.Minute)
				else
					char.Conditions[index] = 0
				end
			end

			-- Update all conditions
			for i = 0, 16 do
				update_condition(i)
			end
			if Game.Version ~= 6 then
				update_condition(17)
			end
		end
	end
end

-- function M.reload()
-- end

function M.firstload()
	update_fields(states.get_char_index())
end

function M.create()
	inputs = {}

	local function condition_row(index)
		local days_input = ui.uint_input(0, {
			SIZE = "40x",
			ALIGNMENT = "ARIGHT"
		})
		local hours_input = ui.uint_input(0, {
			SPINMAX = 23,
			SIZE = "30x",
			ALIGNMENT = "ARIGHT"
		})
		local minutes_input = ui.uint_input(0, {
			SPINMAX = 59,
			SIZE = "30x",
			ALIGNMENT = "ARIGHT"
		})
		local suffix = ""
		if index == 8 or index == 9 then
			suffix = " 2"
		elseif index == 10 or index == 11 then
			suffix = " 3"
		end
		local checkbox = ui.checkbox(utils.const_to_globaltxt("Condition", index) .. suffix, nil, {
			SIZE = "75x"
		})

		-- Store input references
		inputs["checkbox_" .. index] = checkbox
		inputs["days_" .. index] = days_input
		inputs["hours_" .. index] = hours_input
		inputs["minutes_" .. index] = minutes_input

		-- Function to check if any time value is non-zero
		local function check_non_zero()
			local days_val = iup.GetInt(days_input, "VALUE") or 0
			local hours_val = iup.GetInt(hours_input, "VALUE") or 0
			local mins_val = iup.GetInt(minutes_input, "VALUE") or 0
			if days_val > 0 or hours_val > 0 or mins_val > 0 then
				iup.SetAttribute(checkbox, "VALUE", "ON")
			end
			return iup.DEFAULT
		end

		-- Function to reset time inputs when unchecked
		local function on_checkbox_change()
			if iup.GetAttribute(checkbox, "VALUE") ~= "ON" then
				iup.SetAttribute(days_input, "VALUE", "0")
				iup.SetAttribute(hours_input, "VALUE", "0")
				iup.SetAttribute(minutes_input, "VALUE", "0")
			end
			return iup.DEFAULT
		end

		-- Add callbacks to number inputs
		iup.SetCallback(days_input, "VALUECHANGED_CB", check_non_zero)
		iup.SetCallback(hours_input, "VALUECHANGED_CB", check_non_zero)
		iup.SetCallback(minutes_input, "VALUECHANGED_CB", check_non_zero)
		iup.SetCallback(checkbox, "ACTION", on_checkbox_change)

		return ui.hbox({ checkbox, days_input, ui.label(i18n._("days_shortname")), hours_input,
			ui.label(i18n._("hours_shortname")), minutes_input, ui.label(i18n._("minutes_shortname")) })
	end

	local mild_conditions = ui.vbox({ condition_row(0), condition_row(1), condition_row(3), condition_row(4),
		condition_row(5), condition_row(6), condition_row(7) })

	local medium_conditions = ui.vbox({ condition_row(2), condition_row(8), condition_row(9), condition_row(12),
		condition_row(13) })

	local severe_conditions = ui.vbox({ condition_row(10), condition_row(11), condition_row(14), condition_row(15),
		condition_row(16) })

	local other_conditions = nil

	if Game.Version ~= 6 then
		other_conditions = ui.vbox({ condition_row(17) })
	end

	local mild_frame = ui.frame(i18n._("mild_green"), mild_conditions)
	local medium_frame = ui.frame(i18n._("medium_yellow"), medium_conditions)
	local severe_frame = ui.frame(i18n._("severe_red"), severe_conditions)
	local other_frame = nil
	if Game.Version ~= 6 then
		other_frame = ui.frame(i18n._("misc"), other_conditions)
	end

	local hbox_container1 = { mild_frame, medium_frame }
	local hbox_container2 = { severe_frame }
	if Game.Version ~= 6 then
		table.insert(hbox_container2, other_frame)
	end

	return ui.centered_vbox({ ui.hbox(hbox_container1, {
		ALIGNMENT = "ATOP"
	}), ui.hbox(hbox_container2, {
		ALIGNMENT = "ATOP"
	}) }, {
		TABTITLE = i18n._("conditions")
	})
end

return M
