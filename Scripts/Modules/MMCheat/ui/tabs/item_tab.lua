local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local iup = require("iup")
local enc = require("MMCheat/i18n/encoding")
local utils = require("MMCheat/util/utils")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")

local item_image_max_width = 450
local item_image_max_height = 300

local M = {}

local item_select, standard_bonus_select, special_bonus_select
local standard_bonus_value, charges
local identified_checkbox, stolen_checkbox, damaged_checkbox, hardened_checkbox, item_ok_button
local item_image_label_obj
local item_image_array

function M.cleanup()
	item_select, standard_bonus_select, special_bonus_select = nil
	standard_bonus_value, charges = nil
	identified_checkbox, stolen_checkbox, damaged_checkbox, hardened_checkbox, item_ok_button = nil
	item_image_label_obj = nil
	item_image_array = nil
end

function M.firstload()
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
	iup.SetAttribute(standard_bonus_select, "COUNT", tostring(std_bonus_count + 1))
	iup.SetAttribute(standard_bonus_select, "1", i18n._("empty"))
	for i = 0, std_bonus_count - 1 do
		local StdBonus = Game.StdItemsTxt[i]
		iup.SetAttribute(standard_bonus_select, tostring(i + 2),
			enc.decode(StdBonus.NameAdd) ..
			i18n._("left_paren") .. enc.decode(StdBonus.BonusStat) .. i18n._("right_paren"))
	end

	-- Set special bonus select options
	local spc_bonus_count = Game.SpcItemsTxt.Count
	iup.SetAttribute(special_bonus_select, "COUNT", tostring(spc_bonus_count + 1))
	iup.SetAttribute(special_bonus_select, "1", i18n._("empty"))
	for i = 0, spc_bonus_count - 1 do
		local SpcBonus = Game.SpcItemsTxt[i]
		iup.SetAttribute(special_bonus_select, tostring(i + 2),
			enc.decode(SpcBonus.NameAdd) ..
			i18n._("left_paren") .. enc.decode(SpcBonus.BonusStat) .. i18n._("right_paren"))
	end

	-- Load values from Mouse.Item
	local item = Mouse.Item
	if item then
		-- Set item select value (1-based index, with "Empty" as index 1)
		iup.SetAttribute(item_select, "VALUE", tostring(item.Number + 1))

		-- Set standard bonus select value (1-based index, offset by 1 for "empty")
		iup.SetAttribute(standard_bonus_select, "VALUE", tostring(item.Bonus + 1))

		-- Set standard bonus value
		iup.SetAttribute(standard_bonus_value, "VALUE", tostring(item.BonusStrength))

		-- Set special bonus select value (1-based index, offset by 1 for "empty")
		iup.SetAttribute(special_bonus_select, "VALUE", tostring(item.Bonus2 + 1))

		-- Set charges value
		iup.SetAttribute(charges, "VALUE", tostring(item.Charges))

		-- Set checkbox values
		iup.SetAttribute(identified_checkbox, "VALUE", item.Identified and "ON" or "OFF")
		iup.SetAttribute(stolen_checkbox, "VALUE", item.Stolen and "ON" or "OFF")
		iup.SetAttribute(damaged_checkbox, "VALUE", item.Broken and "ON" or "OFF")
		iup.SetAttribute(hardened_checkbox, "VALUE", item.Hardened and "ON" or "OFF")

		local item_image_filename = item_image_array[item.Number]
		item_image_label_obj:load_mm_bitmap_filename(item_image_filename, { "cyan", "magenta" })
	end

	-- Set the button's action callback
	iup.SetCallback(item_ok_button, "ACTION", function()
		local item = Mouse.Item
		if item then
			-- Update item number (1-based index, with "Empty" as index 1)
			local item_value = iup.GetInt(item_select, "VALUE")
			item.Number = item_value > 1 and (item_value - 1) or 0

			-- Update standard bonus (1-based index, with "Empty" as index 1)
			local std_bonus_value = iup.GetInt(standard_bonus_select, "VALUE")
			item.Bonus = std_bonus_value > 1 and (std_bonus_value - 1) or 0

			-- Update standard bonus strength
			item.BonusStrength = iup.GetInt(standard_bonus_value, "VALUE")

			-- Update special bonus (1-based index, with "Empty" as index 1)
			local spc_bonus_value = iup.GetInt(special_bonus_select, "VALUE")
			item.Bonus2 = spc_bonus_value > 1 and (spc_bonus_value - 1) or 0

			-- Update charges
			item.Charges = iup.GetInt(charges, "VALUE")

			-- Update checkbox values
			item.Identified = iup.GetAttribute(identified_checkbox, "VALUE") == "ON"
			item.Stolen = iup.GetAttribute(stolen_checkbox, "VALUE") == "ON"
			item.Broken = iup.GetAttribute(damaged_checkbox, "VALUE") == "ON"
			item.Hardened = iup.GetAttribute(hardened_checkbox, "VALUE") == "ON"
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(item_select, "VALUECHANGED_CB", function()
		local item_value = iup.GetInt(item_select, "VALUE") - 1 -- "Empty" is index 1
		local item_image_filename = item_image_array[item_value]
		item_image_label_obj:load_mm_bitmap_filename(item_image_filename, { "cyan", "magenta" })
		return iup.DEFAULT
	end)
end

function M.create()
	item_select = ui.select()
	standard_bonus_select = ui.select()
	special_bonus_select = ui.select()
	standard_bonus_value = ui.uint_input(0)
	charges = ui.uint_input(0)
	identified_checkbox = ui.checkbox(i18n._("identified"), nil)
	stolen_checkbox = ui.checkbox(i18n._("stolen"), nil)
	damaged_checkbox = ui.checkbox(i18n._("damaged"), nil)
	hardened_checkbox = ui.checkbox(i18n._("hardened"), nil)
	item_ok_button = ui.button(i18n._("ok"), nil, {
		MINSIZE = "60x",
		FGCOLOR = ui.apply_button_color
	})
	item_image_label_obj = ImageLabel:new({
		width = item_image_max_width,
		height = item_image_max_height
	})

	return ui.vbox({ ui.frame(i18n._("item_in_hand"), { ui.vbox(
		{ ui.hbox({ ui.label(i18n._("item")), item_select }),
			ui.hbox({ ui.label(i18n._("standard_bonus")), standard_bonus_select, standard_bonus_value }),
			ui.hbox({ ui.label(i18n._("special_bonus")), special_bonus_select }),
			ui.hbox({ ui.label(i18n._("charges")), charges }),
			ui.hbox({ identified_checkbox, stolen_checkbox, damaged_checkbox, hardened_checkbox }), item_ok_button }, {
			ALIGNMENT = "ACENTER"
		}) }), ui.centered_vbox({ item_image_label_obj.label }) }, {
		TABTITLE = i18n._("item")
	})
end

return M
