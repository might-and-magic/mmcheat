local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local states = require("MMCheat/util/states")

local M = {}

local update_spells, get_spell_states

function M.cleanup()
	update_spells, get_spell_states = nil
end

local function update_fields(char_index)
	local char = Party.PlayersArray[char_index]
	if char then
		-- Update spells
		update_spells(char)
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
			-- Update spells
			local spell_states = get_spell_states()
			for spell_index, is_known in pairs(spell_states) do
				char.Spells[spell_index] = is_known
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
	local groups = { { 1, 11 }, { 12, 22 }, { 23, 33 }, { 34, 44 }, { 45, 55 }, { 56, 66 }, { 67, 77 }, { 78, 88 }, { 89, 99 }, { 100, 103 },
		{ 111, 114 }, { 122, 125 } }

	-- index_to_group: given an index, return the group number or nil if not found
	local function index_to_group(index)
		for i, range in ipairs(groups) do
			if index >= range[1] and index <= range[2] then
				return i
			end
		end
		return nil
	end

	-- group_to_index: given a group number, return start and end index or nil if invalid
	local function group_to_index(group)
		local range = groups[group]
		if range then
			return range[1], range[2]
		end
		return nil, nil
	end

	-- Store all checkbox references
	local spell_checkboxes = {}

	-- Create frames for each spell group
	local function create_spell_group_frame(title_idx, group_idx)
		local vbox = ui.vbox {}
		local group_checkboxes = {}
		local title = enc.decode(Game.SkillNames[title_idx])

		-- Create checkboxes for each spell
		local start_idx, end_idx = group_to_index(group_idx)
		for idx = start_idx, end_idx do
			if Game.SpellsTxt[idx] then
				local spell_name = enc.decode(Game.SpellsTxt[idx].Name)
				local checkbox = ui.checkbox(spell_name, nil)
				spell_checkboxes[idx] = checkbox
				group_checkboxes[idx] = checkbox
				iup.Append(vbox, checkbox)
			end
		end

		-- Add select/deselect all button
		local toggle_all_button = ui.button(i18n._("select_deselect_all"))

		-- Toggle all checkboxes in this group
		local function toggle_all_checkboxes()
			-- Check if all checkboxes are currently checked
			local all_checked = true
			for _, checkbox in pairs(group_checkboxes) do
				if iup.GetAttribute(checkbox, "VALUE") ~= "ON" then
					all_checked = false
					break
				end
			end
			-- Toggle all checkboxes based on current state
			local new_value = all_checked and "OFF" or "ON"
			for _, checkbox in pairs(group_checkboxes) do
				iup.SetAttribute(checkbox, "VALUE", new_value)
			end
			return iup.DEFAULT
		end

		iup.SetCallback(toggle_all_button, "ACTION", toggle_all_checkboxes)
		iup.Append(vbox, ui.centered_vbox(toggle_all_button))

		return ui.frame(title, vbox)
	end

	-- Create frames for magic families (11 spells each)
	local fire_frame = create_spell_group_frame(12, 1)
	local air_frame = create_spell_group_frame(13, 2)
	local water_frame = create_spell_group_frame(14, 3)
	local earth_frame = create_spell_group_frame(15, 4)
	local spirit_frame = create_spell_group_frame(16, 5)
	local mind_frame = create_spell_group_frame(17, 6)
	local body_frame = create_spell_group_frame(18, 7)
	local light_frame = create_spell_group_frame(19, 8)
	local dark_frame = create_spell_group_frame(20, 9)

	-- Create frames for abilities (4 spells each) (MM8 only)
	local dark_elf_frame, vampire_frame, dragon_frame
	if Game.Version == 8 then
		dark_elf_frame = create_spell_group_frame(21, 10)
		vampire_frame = create_spell_group_frame(22, 11)
		dragon_frame = create_spell_group_frame(23, 12)
	end

	-- Create two hboxes, each containing 6 frames
	local first_hbox = ui.hbox({ fire_frame, air_frame, water_frame, earth_frame, spirit_frame, mind_frame }, {
		ALIGNMENT = "ATOP"
	})
	local second_hbox
	local second_hbox_content_table = { body_frame, light_frame, dark_frame }
	if Game.Version == 8 then
		table.insert(second_hbox_content_table, dark_elf_frame)
		table.insert(second_hbox_content_table, vampire_frame)
		table.insert(second_hbox_content_table, dragon_frame)
	end

	second_hbox = ui.hbox(second_hbox_content_table, {
		ALIGNMENT = "ATOP"
	})

	-- Function to update spell checkboxes based on character's known spells
	update_spells = function(char)
		if char and char.Spells then
			for spell_index, checkbox in pairs(spell_checkboxes) do
				iup.SetAttribute(checkbox, "VALUE", char.Spells[spell_index] and "ON" or "OFF")
			end
		end
	end

	-- Function to get spell states from checkboxes
	get_spell_states = function()
		local spell_states = {}
		for spell_index, checkbox in pairs(spell_checkboxes) do
			spell_states[spell_index] = iup.GetAttribute(checkbox, "VALUE") == "ON"
		end
		return spell_states
	end

	return ui.centered_vbox({ first_hbox, second_hbox }, {
		TABTITLE = i18n._("spells")
	})
end

return M
