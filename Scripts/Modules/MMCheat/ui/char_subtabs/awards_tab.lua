local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local utils = require("MMCheat/util/utils")
local enc = require("MMCheat/i18n/encoding")
local states = require("MMCheat/util/states")

local M = {}

local award_list, add_button, remove_button, char_awards

function M.cleanup()
	award_list, add_button, remove_button, char_awards = nil
end

local function update_list(char_index, not_first, not_get_from_game)
	local char = Party.PlayersArray[char_index]

	-- Store current selection before update
	local prev_selection = iup.GetAttribute(award_list, "VALUE")

	if not not_get_from_game then
		if not_first then
			for i = 1, #char_awards do
				char_awards[i].on = char.Awards[i]
			end
		else
			-- Construct awards table
			for i = 1, Game.AwardsTxt.Count - 1 do
				local txt = enc.decode(Game.AwardsTxt[i])
				-- Replace all format specifiers with 0
				txt = txt:gsub("%%[%w]+", "0")
				table.insert(char_awards, {
					txt = txt,
					on = char.Awards[i]
				})
			end
		end
	end

	-- Create display names array
	local display_names = {}
	for i, award in ipairs(char_awards) do
		table.insert(display_names, (award.on and "✓ " or "    ") .. award.txt)
	end

	-- Update list
	utils.load_select_options(award_list, display_names, not_first)

	-- Restore previous selection
	if prev_selection then
		iup.SetAttribute(award_list, "VALUE", prev_selection)
	end
end

-- function M.parent_firstload()
-- end

function M.parent_reload()
	if states.get_charsubtab_loaded(M) then
		update_list(states.get_char_index(), true)
	end
end

function M.parent_select_change()
	if states.get_charsubtab_loaded(M) then
		update_list(states.get_char_index(), true)
	end
end

function M.parent_apply()
	if states.get_charsubtab_loaded(M) then
		local char = Party.PlayersArray[states.get_char_index()]
		for i, award in ipairs(char_awards) do
			if char.Awards[i] ~= award.on then
				char.Awards[i] = award.on
			end
		end
	end
end

-- function M.reload()
-- end

function M.firstload()
	char_awards = {}

	-- Set up button callbacks
	iup.SetCallback(add_button, "ACTION", function()
		local selected = iup.GetAttribute(award_list, "VALUE")
		if selected then
			-- Handle selection string of '+' and '-'
			for i = 1, #selected do
				if selected:sub(i, i) == "+" then
					char_awards[i].on = true
				end
			end
			update_list(states.get_char_index(), true, true)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(remove_button, "ACTION", function()
		local selected = iup.GetAttribute(award_list, "VALUE")
		if selected then
			-- Handle selection string of '+' and '-'
			for i = 1, #selected do
				if selected:sub(i, i) == "+" then
					char_awards[i].on = false
				end
			end
			update_list(states.get_char_index(), true, true)
		end
		return iup.DEFAULT
	end)

	-- Set up double click callback
	iup.SetCallback(award_list, "DBLCLICK_CB", function()
		local selected = iup.GetAttribute(award_list, "VALUE")
		if selected then
			-- Find the double-clicked item (should have only one '+')
			for i = 1, #selected do
				if selected:sub(i, i) == "+" then
					char_awards[i].on = not char_awards[i].on
					break -- Only toggle the first selected item for double-click
				end
			end
			update_list(states.get_char_index(), true, true)
		end
		return iup.DEFAULT
	end)

	update_list(states.get_char_index())
end

function M.create()
	-- Create award list
	award_list = ui.list({}, nil, {
		MULTIPLE = "YES",
		EXPAND = "HORIZONTAL",
		SIZE = "250x250"
	})

	-- Create buttons
	add_button = ui.button(i18n._("add"), nil, {
		MINSIZE = "60x"
	})

	remove_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "60x"
	})

	-- Create button box
	local button_box = ui.button_hbox({ add_button, remove_button }, {
		ALIGNMENT = "ACENTER"
	})

	-- Create main layout
	return ui.vbox({ award_list, button_box }, {
		TABTITLE = i18n._("awards"),
		ALIGNMENT = "ACENTER"
	})
end

return M
