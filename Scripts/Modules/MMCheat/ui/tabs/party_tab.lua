local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")

local M = {}

local food, gold, gold_in_bank, reputation, reputation_desc
local resources_apply, resources_reset
local members, members_apply, members_reset

local min_attack_rc_checkbox, min_melee_rc_input, min_attack_rc_apply, min_attack_rc_reset

function M.cleanup()
	food, gold, gold_in_bank, reputation, reputation_desc = nil
	resources_apply, resources_reset = nil
	members, members_apply, members_reset = nil
	min_attack_rc_checkbox, min_attack_rc_apply, min_attack_rc_reset = nil
end

local use_min_attack_rc = false
local attack_rc_handler_added = false
local min_melee_rc_val_original = Game.MinMeleeRecoveryTime
local min_melee_rc_handler_added = false

local function apply_min_attack_rc()
	local min_attack_rc_val = iup.GetAttribute(min_attack_rc_checkbox, "VALUE") or "OFF"
	if min_attack_rc_val == "ON" and not use_min_attack_rc then
		use_min_attack_rc = true
		if not attack_rc_handler_added then
			---@diagnostic disable-next-line: duplicate-set-field
			function events.LeaveGame()
				if use_min_attack_rc then
					use_min_attack_rc = false
				end
			end

			---@diagnostic disable-next-line: duplicate-set-field
			function events.GetAttackDelay(t)
				if use_min_attack_rc then
					t.Result = 0
				end
			end

			attack_rc_handler_added = true
		end
	end
	if min_attack_rc_val == "OFF" and use_min_attack_rc then
		use_min_attack_rc = false
	end
end

local function apply_min_melee_rc()
	if not min_melee_rc_handler_added then
		---@diagnostic disable-next-line: duplicate-set-field
		function events.LeaveGame()
			if Game.MinMeleeRecoveryTime ~= min_melee_rc_val_original then
				Game.MinMeleeRecoveryTime = min_melee_rc_val_original
			end
		end

		min_melee_rc_handler_added = true
	end

	local min_melee_rc_val = iup.GetInt(min_melee_rc_input, "VALUE") or 0
	Game.MinMeleeRecoveryTime = min_melee_rc_val
end

local function min_attack_rc_reset_from_default()
	iup.SetAttribute(min_attack_rc_checkbox, "VALUE", "OFF")
	iup.SetAttribute(min_melee_rc_input, "VALUE", min_melee_rc_val_original)
end
local function min_attack_rc_reset_from_current()
	iup.SetAttribute(min_attack_rc_checkbox, "VALUE", use_min_attack_rc and "ON" or "OFF")
	iup.SetAttribute(min_melee_rc_input, "VALUE", Game.MinMeleeRecoveryTime)
end

function M.reload()
	-- recheck and update all names in options in cased changed in char
	if Game.Version == 8 then
		for i = 1, #members do
			local char_select = members[i]
			local option_count = iup.GetInt(char_select, "COUNT")
			local current_selection = iup.GetAttribute(char_select, "VALUE")
			for j = 2, option_count do
				local PlayersArrayIndex = j - 2
				local option_text = iup.GetAttribute(char_select, tostring(j))
				local char = Party.PlayersArray[PlayersArrayIndex]
				local current_text = utils.format_character_info(char)
				if option_text ~= current_text then
					iup.SetAttribute(char_select, tostring(j), current_text)
				end
			end
			-- Restore selection
			iup.SetAttribute(char_select, "VALUE", current_selection)
		end
	end
end

function M.firstload()
	local function reset_party_resources()
		iup.SetAttribute(food, "VALUE", Party.Food)
		iup.SetAttribute(gold, "VALUE", Party.Gold)
		iup.SetAttribute(gold_in_bank, "VALUE", Party.BankGold)
		local rep = Party.Reputation
		rep = utils.mm6or78(rep, 0 - rep)
		iup.SetAttribute(reputation, "VALUE", rep)
		iup.SetAttribute(reputation_desc, "VALUE", utils.rep_to_desc(rep))
	end

	-- Function to reset party member selections
	local function reset_members()
		for i = 0, Party.Count - 1 do
			if Party.Players[i] then
				local player_index = Party.Players[i]:GetIndex() -- 0-based
				-- Add 1 because "Empty" is at index 1
				iup.SetAttribute(members[i + 1], "VALUE", player_index + 2)
			end
		end
		if Party.Count < 5 then
			for i = Party.Count, 4 do
				iup.SetAttribute(members[i + 1], "VALUE", 1)
			end
		end
	end

	reset_party_resources()

	iup.SetCallback(reputation, "VALUECHANGED_CB", function()
		local rep = iup.GetInt(reputation, "VALUE") or 0
		iup.SetAttribute(reputation_desc, "VALUE", utils.rep_to_desc(rep))
		return iup.DEFAULT
	end)

	iup.SetCallback(resources_apply, "ACTION", function()
		Party.Food = iup.GetInt(food, "VALUE") or 0
		Party.Gold = iup.GetInt(gold, "VALUE") or 0
		Party.BankGold = iup.GetInt(gold_in_bank, "VALUE") or 0
		local rep = iup.GetInt(reputation, "VALUE") or 0
		Party.Reputation = utils.mm6or78(rep, 0 - rep)
		return iup.DEFAULT
	end)

	iup.SetCallback(resources_reset, "ACTION", function()
		reset_party_resources()
		return iup.DEFAULT
	end)

	min_attack_rc_reset_from_current()

	iup.SetCallback(min_attack_rc_apply, "ACTION", function()
		apply_min_attack_rc()
		apply_min_melee_rc()
		return iup.DEFAULT
	end)

	iup.SetCallback(min_attack_rc_reset, "ACTION", function()
		min_attack_rc_reset_from_default()
		return iup.DEFAULT
	end)

	-- members_frame is mm8-only, no big use in mm6/7
	if Game.Version == 8 then
		local char_names = utils.get_char_name_array(true)

		for i = 1, #members do
			local select_control = members[i]
			utils.load_select_options(select_control, char_names)
		end

		reset_members()

		-- Function to apply party member changes
		local function apply_members()
			if not (Party and Party.Players and Party.PlayersArray) then
				return
			end

			-- Get selected characters (excluding "Empty")
			local selected_chars = {}
			local char_indices = {}
			for i = 1, #members do
				local selected_index = iup.GetInt(members[i], "VALUE")
				if selected_index and selected_index > 1 then -- Not "Empty"
					local char_index = selected_index - 2 -- Convert to Party.PlayersArray's 0-based index
					if char_indices[char_index] then
						-- Duplicate character found
						iup.Message(i18n._("warning"), i18n._("duplicate_characters_not_allowed"))
						return
					end
					char_indices[char_index] = true
					table.insert(selected_chars, char_index)
				end
			end

			if #selected_chars == 0 then
				iup.Message(i18n._("warning"), i18n._("must_have_at_least_one_character"))
				return
			end

			-- Update party
			Party.Count = #selected_chars
			for i, v in ipairs(selected_chars) do
				Party.Players[i - 1] = Party.PlayersArray[v]
			end

			reset_members()
		end

		iup.SetCallback(members_apply, "ACTION", function()
			apply_members()
			return iup.DEFAULT
		end)

		iup.SetCallback(members_reset, "ACTION", function()
			reset_members()
			return iup.DEFAULT
		end)
	end
end

function M.create()
	food = ui.uint_input(0, {
		SIZE = "80x"
	})
	gold = ui.uint_input(0, {
		SIZE = "80x"
	})
	gold_in_bank = ui.uint_input(0, {
		SIZE = "80x"
	})
	reputation = ui.int_input(0, {
		SIZE = "80x"
	})
	reputation_desc = ui.input(0, {
		READONLY = "YES",
		BGCOLOR = ui.non_editable_input_bg_color,
		SIZE = "120x"
	})

	resources_apply = ui.button(i18n._("apply"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	resources_reset = ui.button(i18n._("reset"), nil, {
		MINSIZE = "60x"
	})

	local resources_frame = ui.frame(i18n._("resources"), ui.vbox(
		{ ui.vbox({ ui.labelled_fields(i18n._("food"), { food }),
			ui.hbox(
				{ ui.labelled_fields(i18n._("gold"), { gold }), ui.labelled_fields(i18n._("gold_in_bank"),
					{ gold_in_bank }) }),
			ui.labelled_fields(i18n._("reputation"), { reputation, reputation_desc }) }),
			ui.button_hbox({ resources_apply, resources_reset }) }, {
			ALIGNMENT = "ACENTER"
		}))

	-- UI frame for MM7
	local ui_frame
	if Game.Version == 7 then
		local ui_select = ui.select({ i18n._("default"), i18n._("light_path"), i18n._("dark_path") })
		local ui_apply = ui.button(i18n._("apply"), nil, {
			MINSIZE = "60x",
			FGCOLOR = ui.apply_button_color
		})

		-- Apply button callback
		iup.SetCallback(ui_apply, "ACTION", function()
			local selected = iup.GetInt(ui_select, "VALUE")
			if selected then
				if selected == 2 then
					selected = 0
				elseif selected == 3 then
					selected = 2
				end
				Game.SetInterfaceColor(selected)
			end
			return iup.DEFAULT
		end)

		ui_frame = ui.frame(i18n._("ui_theme"), ui.hbox({ ui.label(i18n._("ui_theme")), ui_select, ui_apply }))
	end

	local members_frame

	if Game.Version == 8 then
		members = {}
		for i = 1, 5 do
			members[i] = ui.select {}
		end

		members_apply = ui.button(i18n._("apply_save_reload"), nil, {
			FGCOLOR = ui.apply_button_color
		})
		members_reset = ui.button(i18n._("reset"), nil, {
			MINSIZE = "60x"
		})

		local party_member_boxes = {}
		for i = 1, #members do
			table.insert(party_member_boxes, ui.hbox({ ui.label(tostring(i)), members[i] }))
		end

		members_frame = ui.frame(i18n._("members"),
			ui.vbox({ ui.vbox(party_member_boxes), ui.button_hbox({ members_apply, members_reset }) }, {
				ALIGNMENT = "ACENTER"
			}))
	end

	min_attack_rc_checkbox = ui.checkbox(
		i18n._("use_min_melee_shooting"), nil,
		{
			FGCOLOR = ui.onetime_change_label_color
		})
	min_melee_rc_input = ui.uint_input(nil, {
		SIZE = "40x"
	})
	min_attack_rc_apply = ui.button(i18n._("apply"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	min_attack_rc_reset = ui.button(i18n._("default"), nil, {
		MINSIZE = "60x"
	})

	local recovery_time_frame = ui.frame(i18n._("attack_recovery_time"), ui.centered_vbox({
		min_attack_rc_checkbox,
		ui.hbox({
			ui.label(i18n._("min_melee"), {
				FGCOLOR = ui.onetime_change_label_color
			}),
			min_melee_rc_input
		}),
		ui.button_hbox({
			min_attack_rc_apply,
			min_attack_rc_reset
		})
	}))

	local top_line = ui.hbox({ resources_frame, recovery_time_frame }, {
		ALIGNMENT = "ATOP"
	})

	local content_table = { top_line }
	if Game.Version == 7 then
		table.insert(content_table, ui_frame)
	end
	if Game.Version == 8 then
		table.insert(content_table, members_frame)
	end

	return ui.centered_vbox(content_table, {
		TABTITLE = i18n._("party")
	})
end

return M
