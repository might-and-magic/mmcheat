local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")

local item_image_max_width = 450
local item_image_max_height = 300

local M = {}

local inventory_list, item_select, bonus1, bonus1_value, bonus2, charges, apply_button, remove_button
local identified, stolen, damaged, hardened
local valid_items
local item_image_label_obj
local item_image_array

function M.cleanup()
	inventory_list, item_select, bonus1, bonus1_value, bonus2, charges, apply_button, remove_button = nil
	identified, stolen, damaged, hardened = nil
	valid_items = nil
	item_image_label_obj = nil
	item_image_array = nil
end

-- Function to set valid_items
local function set_valid_items(char_index)
	local char = Party.PlayersArray[char_index]
	if char then
		-- Empty valid_items first
		for k in pairs(valid_items) do
			valid_items[k] = nil
		end

		-- Add all non-zero items to the list
		for i = 1, char.Items.Count do
			local item = char.Items[i]
			if item.Number ~= 0 then
				local item_info = Game.ItemsTxt[item.Number]
				if item_info then
					-- Check if item is equipped
					local equipped = false
					for j = 0, char.EquippedItems.Count - 1 do
						if char.EquippedItems[j] == i then
							equipped = true
							break
						end
					end
					valid_items[#valid_items + 1] = {
						name = enc.decode(item_info.Name),
						index = i,
						equipped = equipped
					}
				end
			end
		end
	end
end

-- Function to update all fields based on selected item. If no selected_index, then it's not selected
local function update_fields(char_index, selected_index)
	if not char_index or not selected_index then
		-- Clear all fields
		iup.SetAttribute(item_select, "VALUE", "1") -- "Empty"
		iup.SetAttribute(bonus1, "VALUE", "1") -- "None"
		iup.SetAttribute(bonus1_value, "VALUE", "0")
		iup.SetAttribute(bonus2, "VALUE", "1") -- "None"
		iup.SetAttribute(charges, "VALUE", "0")
		iup.SetAttribute(identified, "VALUE", "ON")
		iup.SetAttribute(stolen, "VALUE", "OFF")
		iup.SetAttribute(damaged, "VALUE", "OFF")
		iup.SetAttribute(hardened, "VALUE", "OFF")
		return
	end

	local char = Party.PlayersArray[char_index]
	if char then
		local item_index = valid_items[selected_index].index
		local item = char.Items[item_index]

		if item and item.Number ~= 0 then
			-- Set item select value (1-based index, with "Empty" as index 1)
			iup.SetAttribute(item_select, "VALUE", tostring(item.Number + 1))

			-- Set standard bonus select value (1-based index, with "Empty" as index 1)
			iup.SetAttribute(bonus1, "VALUE", tostring(item.Bonus + 1))

			-- Set standard bonus value
			iup.SetAttribute(bonus1_value, "VALUE", tostring(item.BonusStrength))

			-- Set special bonus select value (1-based index, with "Empty" as index 1)
			iup.SetAttribute(bonus2, "VALUE", tostring(item.Bonus2 + 1))

			-- Set charges value
			iup.SetAttribute(charges, "VALUE", tostring(item.Charges))

			-- Set checkbox values
			iup.SetAttribute(identified, "VALUE", item.Identified and "ON" or "OFF")
			iup.SetAttribute(stolen, "VALUE", item.Stolen and "ON" or "OFF")
			iup.SetAttribute(damaged, "VALUE", item.Broken and "ON" or "OFF")
			iup.SetAttribute(hardened, "VALUE", item.Hardened and "ON" or "OFF")
		end
	end
end

-- Function to refresh inventory list
local function refresh_inventory_list(char_index)
	-- Renew valid_items table
	set_valid_items(char_index)

	local sorted_item_names = { i18n._("add_new_item") }
	for i, v in ipairs(valid_items) do
		local name = v.name
		if v.equipped then
			name = name .. " *"
		end
		table.insert(sorted_item_names, name)
	end

	utils.load_select_options(inventory_list, sorted_item_names, true)
end

-- function M.parent_firstload()
-- end

function M.parent_reload()
	if states.get_charsubtab_loaded(M) then
		refresh_inventory_list(states.get_char_index())
		iup.SetAttribute(inventory_list, "VALUE", "1") -- default selection is "[Add new item]"
		update_fields()
	end
end

function M.parent_select_change()
	if states.get_charsubtab_loaded(M) then
		refresh_inventory_list(states.get_char_index())
		iup.SetAttribute(inventory_list, "VALUE", "1") -- default selection is "[Add new item]"
		update_fields()
	end
end

-- function M.parent_apply()
-- end

-- function M.reload()
-- end

local function set_image(item_number)
	local item_image_filename = item_image_array[item_number]
	item_image_label_obj:load_mm_bitmap_filename(item_image_filename, { "cyan", "magenta" })
end

function M.firstload()
	valid_items = {}
	item_image_array = {}

	-- Set item select options
	local item_count = Game.ItemsTxt.Count - 1
	iup.SetAttribute(item_select, "COUNT", tostring(item_count + 1)) -- +1 for "Empty" option
	iup.SetAttribute(item_select, "1", i18n._("empty"))           -- Add "Empty" as first option
	for i = 1, item_count do
		local item = Game.ItemsTxt[i]
		iup.SetAttribute(item_select, tostring(i + 1), utils.format_item_info(item)) -- +1 to account for "Empty" option
		item_image_array[i] = item.Picture
	end

	-- Set standard bonus select options
	local std_bonus_count = Game.StdItemsTxt.Count
	iup.SetAttribute(bonus1, "COUNT", tostring(std_bonus_count + 1))
	iup.SetAttribute(bonus1, "1", i18n._("empty"))
	for i = 0, std_bonus_count - 1 do
		local StdBonus = Game.StdItemsTxt[i]
		iup.SetAttribute(bonus1, tostring(i + 2),
			enc.decode(StdBonus.NameAdd) ..
			i18n._("left_paren") .. enc.decode(StdBonus.BonusStat) .. i18n._("right_paren"))
	end

	-- Set special bonus select options
	local spc_bonus_count = Game.SpcItemsTxt.Count
	iup.SetAttribute(bonus2, "COUNT", tostring(spc_bonus_count + 1))
	iup.SetAttribute(bonus2, "1", i18n._("empty"))
	for i = 0, spc_bonus_count - 1 do
		local SpcBonus = Game.SpcItemsTxt[i]
		iup.SetAttribute(bonus2, tostring(i + 2),
			enc.decode(SpcBonus.NameAdd) ..
			i18n._("left_paren") .. enc.decode(SpcBonus.BonusStat) .. i18n._("right_paren"))
	end

	refresh_inventory_list(states.get_char_index())
	iup.SetAttribute(inventory_list, "VALUE", "1") -- default selection is "[Add new item]"
	update_fields()

	-- Set callbacks
	iup.SetCallback(inventory_list, "VALUECHANGED_CB", function()
		local selected = iup.GetInt(inventory_list, "VALUE")
		if selected == 1 then
			update_fields()
			-- Clear image when no item selected
			set_image(nil)
		elseif selected > 1 then
			update_fields(states.get_char_index(), selected - 1)
			-- Update image for selected item
			local char = Party.PlayersArray[states.get_char_index()]
			if char then
				local valid_item = valid_items[selected - 1]
				local item_index = valid_item.index
				local item = char.Items[item_index]
				if item and item.Number ~= 0 then
					set_image(item.Number)
				end
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(item_select, "VALUECHANGED_CB", function()
		local item_index = iup.GetInt(item_select, "VALUE") - 1 -- "Empty" is index 1
		set_image(item_index)
		return iup.DEFAULT
	end)

	iup.SetCallback(apply_button, "ACTION", function()
		local selected = iup.GetInt(inventory_list, "VALUE")
		if selected == 1 then
			local props = {}
			props.Number = iup.GetInt(item_select, "VALUE") - 1
			props.Bonus = iup.GetInt(bonus1, "VALUE") - 1
			props.BonusStrength = iup.GetInt(bonus1_value, "VALUE")
			props.Bonus2 = iup.GetInt(bonus2, "VALUE") - 1
			props.Charges = iup.GetInt(charges, "VALUE")
			props.Identified = iup.GetAttribute(identified, "VALUE") == "ON"
			props.Stolen = iup.GetAttribute(stolen, "VALUE") == "ON"
			props.Broken = iup.GetAttribute(damaged, "VALUE") == "ON"
			props.Hardened = iup.GetAttribute(hardened, "VALUE") == "ON"

			local item_slot_index = utils.add_item(states.get_char_index(), props)

			if item_slot_index then
				-- Update UI
				refresh_inventory_list(states.get_char_index())

				-- Select the newly added item
				local select_index
				for i, item in ipairs(valid_items) do
					if item.index == item_slot_index then
						select_index = i + 1
						break
					end
				end
				iup.SetAttribute(inventory_list, "VALUE", tostring(select_index))
			end
		elseif selected > 1 then
			local char = Party.PlayersArray[states.get_char_index()]
			if char and char.Items then
				local valid_item = valid_items[selected - 1]
				local item_index = valid_item.index
				local equipped = valid_item.equipped
				if item_index then
					local selected_item = char.Items[item_index]
					if selected_item then
						local should_proceed = true
						local new_number = iup.GetInt(item_select, "VALUE") - 1
						if equipped and selected_item.Number ~= new_number and
							Game.ItemsTxt[selected_item.Number].EquipStat ~= Game.ItemsTxt[new_number].EquipStat then -- item is equipped, number and EquipStat both changed
							local choice = iup.Alarm(i18n._("warning"), i18n._("change_equipped_item_warning"),
								i18n._("yes"), i18n._("no"))                                     -- 0: Cancel; 1: Yes ; 2: No
							should_proceed = choice == 1
						end
						if should_proceed then
							selected_item.Number = new_number
							selected_item.Bonus = iup.GetInt(bonus1, "VALUE") - 1
							selected_item.BonusStrength = iup.GetInt(bonus1_value, "VALUE")
							selected_item.Bonus2 = iup.GetInt(bonus2, "VALUE") - 1
							selected_item.Charges = iup.GetInt(charges, "VALUE")
							selected_item.Identified = iup.GetAttribute(identified, "VALUE") == "ON"
							selected_item.Stolen = iup.GetAttribute(stolen, "VALUE") == "ON"
							selected_item.Broken = iup.GetAttribute(damaged, "VALUE") == "ON"
							selected_item.Hardened = iup.GetAttribute(hardened, "VALUE") == "ON"

							-- Update UI
							refresh_inventory_list(states.get_char_index())
							iup.SetAttribute(inventory_list, "VALUE", tostring(selected))
						end
					end
				end
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(remove_button, "ACTION", function()
		local selected = iup.GetInt(inventory_list, "VALUE")
		if selected == 1 then
			update_fields()
		elseif selected > 1 then
			local valid_item = valid_items[selected - 1]
			local item_index = valid_item.index
			local removed = utils.remove_item(states.get_char_index(), item_index)

			if removed ~= nil then
				-- Update UI
				refresh_inventory_list(states.get_char_index())

				-- Select next item or previous if at end
				local count = iup.GetInt(inventory_list, "COUNT")
				local new_selection = math.min(selected, count)
				iup.SetAttribute(inventory_list, "VALUE", tostring(new_selection))
				local selected_index = new_selection - 1
				if count == 1 then
					selected_index = nil
				end
				update_fields(states.get_char_index(), selected_index)
			end
		end
		return iup.DEFAULT
	end)
end

function M.create()
	inventory_list = ui.list({}, nil, {
		SIZE = "220x250"
	})
	item_select = ui.select()
	bonus1 = ui.select()
	bonus1_value = ui.uint_input(0, {
		SIZE = "40x"
	})
	bonus2 = ui.select()
	charges = ui.uint_input(0, {
		SIZE = "40x"
	})
	identified = ui.checkbox(i18n._("identified"), nil)
	stolen = ui.checkbox(i18n._("stolen"), nil)
	damaged = ui.checkbox(i18n._("damaged"), nil)
	hardened = ui.checkbox(i18n._("hardened"), nil)

	apply_button = ui.button(i18n._("apply"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	remove_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})

	item_image_label_obj = ImageLabel:new({
		width = item_image_max_width,
		height = item_image_max_height
	})

	local inventory_box = ui.vbox(
		{ ui.label(i18n._("inventory") .. i18n._("nn") .. i18n._("equipment")), inventory_list,
			ui.label("*" .. i18n._("colon") .. i18n._("equipped")) })

	local fields_box = ui.vbox({ ui.labelled_fields(i18n._("item"), { item_select }, 80),
		ui.labelled_fields(i18n._("standard_bonus"), { bonus1, bonus1_value }, 80),
		ui.labelled_fields(i18n._("special_bonus"), { bonus2 }, 80),
		ui.labelled_fields(i18n._("charges"), { charges }, 80),
		ui.hbox({ identified, stolen, damaged, hardened }),
		ui.button_hbox({ apply_button, remove_button }), item_image_label_obj.label }, {
		ALIGNMENT = "ACENTER"
	})

	return ui.hbox({ inventory_box, fields_box }, {
		TABTITLE = i18n._("items"),
		ALIGNMENT = "ACENTER"
	})
end

return M
