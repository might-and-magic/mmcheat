local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local lazytabs = require("MMCheat/ui/components/lazytabs")
local i18n = require("MMCheat/i18n/i18n")
local basics_tab = require("MMCheat/ui/char_subtabs/basics_tab")
local stats_res_tab = require("MMCheat/ui/char_subtabs/stats_res_tab")
local skills_tab = require("MMCheat/ui/char_subtabs/skills_tab")
local char_spells_tab = require("MMCheat/ui/char_subtabs/char_spells_tab")
local char_active_spells_tab = require("MMCheat/ui/char_subtabs/char_active_spells_tab")
local items_tab = require("MMCheat/ui/char_subtabs/items_tab")
local conditions_tab = require("MMCheat/ui/char_subtabs/conditions_tab")
local awards_tab = require("MMCheat/ui/char_subtabs/awards_tab")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")

local tabs = { basics_tab, stats_res_tab, skills_tab, char_spells_tab, char_active_spells_tab, items_tab, conditions_tab,
	awards_tab }

local M = {}

local character_select

function M.cleanup()
	character_select = nil
end

function M.reload()
	for i, tab in ipairs(tabs) do
		if tab.parent_reload then
			tab.parent_reload()
		end
	end
end

function M.firstload()
	states.set_charsubtab_loaded(tabs[1], true)

	utils.load_select_options(character_select, utils.get_char_name_array())

	-- Set default character
	local default_character_index = Party.GetCurrentPlayer():GetIndex()
	iup.SetAttribute(character_select, "VALUE", default_character_index + 1)
	states.set_char_index(default_character_index)

	for i, tab in ipairs(tabs) do
		if tab.parent_firstload then
			tab.parent_firstload()
		end
		if i == 1 and tab.firstload then
			tab.firstload()
		end
	end
end

function M.create()
	character_select = ui.select {}

	-- Add callback to update all fields when character is selected
	iup.SetCallback(character_select, "VALUECHANGED_CB", function()
		local selected_index = iup.GetInt(character_select, "VALUE")
		if selected_index then
			local char_index = selected_index - 1
			states.set_char_index(char_index)
			for i, tab in ipairs(tabs) do
				if tab.parent_select_change then
					tab.parent_select_change()
				end
			end
		end
		return iup.DEFAULT
	end)

	local sub_tabs, tab_info = lazytabs(tabs, nil, true)
	states.set_charsubtab_info_table(tab_info)

	local apply_button = ui.button(i18n._("apply_changes_below"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "180x"
	})

	iup.SetCallback(apply_button, "ACTION", function()
		local selected_index = iup.GetInt(character_select, "VALUE")
		if selected_index then
			local char_index = selected_index - 1

			-- cache old_* to use them later
			local char = Party.PlayersArray[char_index]
			local old_name = char.Name
			local old_levelbase = char.LevelBase
			local old_class = char.Class

			for i, tab in ipairs(tabs) do
				if tab.parent_apply then
					tab.parent_apply()
				end
			end

			-- Update the character name, level base and class in the dropdown if they changed
			if char.Name ~= old_name or char.LevelBase ~= old_levelbase or char.Class ~= old_class then
				local selected_index_string = tostring(selected_index)
				-- Update. The selection could change here
				iup.SetAttribute(character_select, selected_index_string, utils.format_character_info(char))
				-- Restore selection
				iup.SetAttribute(character_select, "VALUE", selected_index_string)
			end
		end
		return iup.DEFAULT
	end)

	return ui.vbox({ ui.hbox({ ui.label(i18n._("select_character")), character_select, apply_button }), sub_tabs }, {
		TABTITLE = i18n._("characters"),
		ALIGNMENT = "ACENTER"
	})
end

return M
