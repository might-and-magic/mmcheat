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
		-- Update stats and resistances
		for _, stat in ipairs(utils.get_7stats()) do
			local stat_lower = stat:lower()
			iup.SetAttribute(inputs[stat_lower .. "_base"], "VALUE", char[stat .. "Base"] or 0)
			iup.SetAttribute(inputs[stat_lower .. "_bonus"], "VALUE", char[stat .. "Bonus"] or 0)
			iup.SetAttribute(inputs[stat_lower .. "_total"], "VALUE",
				(char[stat .. "Base"] or 0) + (char[stat .. "Bonus"] or 0))
		end
		for _, res in ipairs(utils.get_res()) do
			local res_lower = res:lower()
			iup.SetAttribute(inputs[res_lower .. "_resist_base"], "VALUE", char[res .. "ResistanceBase"] or 0)
			iup.SetAttribute(inputs[res_lower .. "_resist_bonus"], "VALUE", char[res .. "ResistanceBonus"] or 0)
			iup.SetAttribute(inputs[res_lower .. "_resist_total"], "VALUE",
				(char[res .. "ResistanceBase"] or 0) + (char[res .. "ResistanceBonus"] or 0))
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
			-- Update stats and resistances
			for _, stat in ipairs(utils.get_7stats()) do
				local stat_lower = stat:lower()
				local base = iup.GetInt(inputs[stat_lower .. "_base"], "VALUE") or 0
				local bonus = iup.GetInt(inputs[stat_lower .. "_bonus"], "VALUE") or 0
				char[stat .. "Base"] = base
				char[stat .. "Bonus"] = bonus
			end
			for _, res in ipairs(utils.get_res()) do
				local res_lower = res:lower()
				local base = iup.GetInt(inputs[res_lower .. "_resist_base"], "VALUE") or 0
				local bonus = iup.GetInt(inputs[res_lower .. "_resist_bonus"], "VALUE") or 0
				char[res .. "ResistanceBase"] = base
				char[res .. "ResistanceBonus"] = bonus
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
	local stats_frame_inputs = {}
	local res_frame_inputs = {}

	-- Create inputs for 7 stats
	for _, stat in ipairs(utils.get_7stats()) do
		local stat_lower = stat:lower()
		inputs[stat_lower .. "_base"] = ui.int_input(0, {
			SIZE = "40x"
		})
		inputs[stat_lower .. "_bonus"] = ui.int_input(0, {
			SIZE = "40x"
		})
		inputs[stat_lower .. "_total"] = ui.input(0, {
			READONLY = "YES",
			SIZE = "40x",
			BGCOLOR = ui.non_editable_input_bg_color
		})
		stats_frame_inputs[stat] = {
			base = inputs[stat_lower .. "_base"],
			bonus = inputs[stat_lower .. "_bonus"],
			total = inputs[stat_lower .. "_total"]
		}
	end

	-- Create inputs for resistances
	for _, res in ipairs(utils.get_res()) do
		local res_lower = res:lower()
		inputs[res_lower .. "_resist_base"] = ui.uint_input(0, {
			SIZE = "40x"
		})
		inputs[res_lower .. "_resist_bonus"] = ui.uint_input(0, {
			SIZE = "40x"
		})
		inputs[res_lower .. "_resist_total"] = ui.input(0, {
			READONLY = "YES",
			SIZE = "40x",
			BGCOLOR = ui.non_editable_input_bg_color
		})
		res_frame_inputs[res] = {
			base = inputs[res_lower .. "_resist_base"],
			bonus = inputs[res_lower .. "_resist_bonus"],
			total = inputs[res_lower .. "_resist_total"]
		}
	end

	-- Function to update total when base or bonus changes
	local function update_total(base_input, bonus_input, total_input)
		local base = iup.GetInt(base_input, "VALUE") or 0
		local bonus = iup.GetInt(bonus_input, "VALUE") or 0
		iup.SetAttribute(total_input, "VALUE", base + bonus)
	end

	-- Set up change handlers for all base/bonus inputs
	local function setup_total_update(base, bonus, total)
		iup.SetCallback(base, "VALUECHANGED_CB", function()
			update_total(base, bonus, total)
			return iup.DEFAULT
		end)
		iup.SetCallback(bonus, "VALUECHANGED_CB", function()
			update_total(base, bonus, total)
			return iup.DEFAULT
		end)
	end

	-- Set up all total updates for stats
	for _, stat in ipairs(utils.get_7stats()) do
		local inputs = stats_frame_inputs[stat]
		setup_total_update(inputs.base, inputs.bonus, inputs.total)
	end

	-- Set up all total updates for resistances
	for _, res in ipairs(utils.get_res()) do
		local inputs = res_frame_inputs[res]
		setup_total_update(inputs.base, inputs.bonus, inputs.total)
	end

	-- Create stats frame
	local stats_fields = {}
	for _, stat in ipairs(utils.get_7stats()) do
		local inputs = stats_frame_inputs[stat]
		table.insert(stats_fields, ui.labelled_fields(utils.text_to_globaltxt(stat),
			{ ui.label(i18n._("base")), inputs.base, ui.label(i18n._("bonus")), inputs.bonus, ui.label(i18n._("total")),
				inputs.total }, nil, true))
	end

	local seven_stats_frame = ui.frame(i18n._("seven_stats"), ui.vbox(stats_fields, {
		ALIGNMENT = "ACENTER"
	}))

	-- Create resistances frame
	local res_fields = {}
	for _, res in ipairs(utils.get_res()) do
		local inputs = res_frame_inputs[res]
		local res_txt = res
		if res_txt == "Elec" then
			res_txt = "Electricity"
		end
		table.insert(res_fields, ui.labelled_fields(utils.text_to_globaltxt(res_txt),
			{ ui.label(i18n._("base")), inputs.base, ui.label(i18n._("bonus")), inputs.bonus, ui.label(i18n._("total")),
				inputs.total }, nil, true))
	end

	local resistances_frame = ui.frame(i18n._("resistances"), ui.vbox(res_fields))

	return ui.centered_vbox({ ui.hbox({ seven_stats_frame, resistances_frame }, {
		ALIGNMENT = "ATOP"
	}) }, {
		TABTITLE = i18n._("stats") .. i18n._("nn") .. i18n._("resistances")
	})
end

return M
