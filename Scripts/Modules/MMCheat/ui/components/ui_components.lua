local iup = require("iup")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local states = require("MMCheat/util/states")

local M = {}

function M.input(value, attrs)
	local ret = iup.text(nil)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	iup.SetAttribute(ret, "VALUE", value or "")
	return ret
end

function M.int_input(value, attrs)
	local ret = iup.text(nil)
	iup.SetAttribute(ret, "SPIN", "YES")
	iup.SetAttribute(ret, "SPINMAX", 2147483646)
	iup.SetAttribute(ret, "SPINMIN", -2147483647)
	iup.SetAttribute(ret, "MASK", iup.MASK_INT)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	iup.SetAttribute(ret, "VALUE", value or 0)
	return ret
end

function M.uint_input(value, attrs)
	local ret = iup.text(nil)
	iup.SetAttribute(ret, "SPIN", "YES")
	iup.SetAttribute(ret, "SPINMAX", 2147483646)
	iup.SetAttribute(ret, "SPINMIN", 0)
	iup.SetAttribute(ret, "MASK", iup.MASK_UINT)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	iup.SetAttribute(ret, "VALUE", value or 0)
	return ret
end

function M.fill(attrs)
	local ret = iup.fill()
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.vbox(children, attrs)
	local ret
	if type(children) == "table" then
		---@diagnostic disable-next-line: deprecated
		ret = iup.vbox(unpack(children))
	else
		ret = iup.vbox(children)
	end
	iup.SetAttribute(ret, "MARGIN", "4x4")
	iup.SetAttribute(ret, "GAP", "2")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

-- vbox with horizontally centered items
function M.centered_vbox(children, attrs, fill_attrs)
	local new_children = { M.hbox({ M.fill(fill_attrs) }, {
		MARGIN = "0x0"
	}) }
	if type(children) == "table" then
		for _, child in ipairs(children) do
			table.insert(new_children, child)
		end
	else
		table.insert(new_children, children)
	end
	local new_attrs = {
		MARGIN = "0x0",
		ALIGNMENT = "ACENTER"
	}
	if attrs then
		for k, v in pairs(attrs) do
			new_attrs[k] = v
		end
	end
	return M.vbox(new_children, new_attrs)
end

function M.hbox(children, attrs)
	local ret
	if type(children) == "table" then
		---@diagnostic disable-next-line: deprecated
		ret = iup.hbox(unpack(children))
	else
		ret = iup.hbox(children)
	end
	iup.SetAttribute(ret, "MARGIN", "4x4")
	iup.SetAttribute(ret, "GAP", "2")
	iup.SetAttribute(ret, "ALIGNMENT", "ACENTER")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.button_vbox(children, attrs)
	local ret = M.vbox(children, attrs)
	iup.SetAttribute(ret, "GAP", "5")
	iup.SetAttribute(ret, "ALIGNMENT", "ACENTER")
	return ret
end

function M.button_hbox(children, attrs)
	local ret = M.hbox(children, attrs)
	iup.SetAttribute(ret, "GAP", "5")
	return ret
end

function M.frame(title, children, attrs)
	local ret
	if type(children) == "table" then
		---@diagnostic disable-next-line: deprecated
		ret = iup.frame(unpack(children))
	else
		ret = iup.frame(children)
	end
	iup.SetAttribute(ret, "TITLE", title)
	iup.SetAttribute(ret, "MARGIN", "4x4")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.button(title, action, attrs)
	local ret = iup.button(title, action)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.label(title, attrs)
	local ret = iup.label(title)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.labelled_fields(label, fields, label_min_width, left_align, label_attrs)
	label_min_width = label_min_width or 80
	left_align = left_align or false
	local my_label_attrs = {}
	if label_attrs then
		for k, v in pairs(label_attrs) do
			my_label_attrs[k] = v
		end
	end
	my_label_attrs.MINSIZE = label_min_width .. "x"
	my_label_attrs.ALIGNMENT = left_align and "ALEFT" or "ARIGHT"
	local label_control = M.label(label, my_label_attrs)
	local input_controls = { label_control }
	for _, input in ipairs(fields) do
		table.insert(input_controls, input)
	end
	return M.hbox(input_controls)
end

function M.checkbox(title, action, attrs)
	local ret = iup.toggle(title, action)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.tabs(children, attrs)
	local ret
	if type(children) == "table" then
		---@diagnostic disable-next-line: deprecated
		ret = iup.tabs(unpack(children))
	else
		ret = iup.tabs(children)
	end
	iup.SetAttribute(ret, "MULTILINE", "YES")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.dialog(children, attrs)
	local ret
	if type(children) == "table" then
		---@diagnostic disable-next-line: deprecated
		ret = iup.dialog(unpack(children))
	else
		ret = iup.dialog(children)
	end
	iup.SetAttribute(ret, "ICON", states.logo.handle_name)
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

function M.multiline(value, attrs)
	local ret = iup.multiline(nil)
	iup.SetAttribute(ret, "VALUE", value or "")
	iup.SetAttribute(ret, "EXPAND", "HORIZONTAL")
	iup.SetAttribute(ret, "WORDWRAP", "YES")
	iup.SetAttribute(ret, "VISIBLELINES", "6")
	iup.SetAttribute(ret, "AUTOHIDE", "YES")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end
	return ret
end

-- Helper function for Ctrl+F search and Ctrl+C copy callback
local function create_keypress_callback(list_control, is_multiple)
	return function(ih, c)
		if c == iup.XKeyCtrl(iup.K_F) then -- Ctrl+F
			-- Get current items from the list
			local current_items = {}
			local count = iup.GetInt(list_control, "COUNT")
			for i = 1, count do
				local item = iup.GetAttribute(list_control, tostring(i))
				if item then
					table.insert(current_items, item)
				end
			end

			-- Create search dialog
			local search_input = M.input(nil, {
				EXPAND = "HORIZONTAL",
				MINSIZE = "400x",
				MAXSIZE = "800x"
			})

			local search_list = iup.list(nil)
			iup.SetAttribute(search_list, "EXPAND", "YES")
			iup.SetAttribute(search_list, "MINSIZE", "400x")
			iup.SetAttribute(search_list, "MAXSIZE", "800x")
			iup.SetAttribute(search_list, "VISIBLELINES", "28")

			-- Initialize table of options and mapping table
			local table_of_options = {}
			local map_table = {}

			-- Copy items to search list and initialize mapping
			for i, v in ipairs(current_items) do
				table.insert(table_of_options, v)
				map_table[i] = i
			end
			utils.load_select_options(search_list, table_of_options, true)

			-- Create OK button
			local ok_button = M.button(i18n._("ok"), nil, {
				MINSIZE = "80x"
			})

			-- Create dialog layout
			local main_box = M.vbox({ search_input, search_list, ok_button }, {
				ALIGNMENT = "ACENTER"
			})
			iup.SetAttribute(main_box, "MARGIN", "4x4")
			iup.SetAttribute(main_box, "GAP", "2")

			local dialog_callbacks = {}
			local dialog = M.dialog({ main_box }, {
				TITLE = i18n._("find_in_list"),
				BRINGFRONT = "YES"
			})

			-- Set up search input callback
			iup.SetCallback(search_input, "VALUECHANGED_CB", function(ih)
				table.insert(dialog_callbacks, ih)
				local search_text = iup.GetAttribute(search_input, "VALUE")
				search_text = search_text:lower()

				-- Clear and refill list with filtered items
				table_of_options = {}
				map_table = {}
				local count = 1
				for i, v in ipairs(current_items) do
					if v:lower():find(search_text, 1, true) then
						table.insert(table_of_options, v)
						map_table[count] = i
						count = count + 1
					end
				end
				utils.load_select_options(search_list, table_of_options, true)

				-- Select first entry if there are any results
				if #table_of_options > 0 then
					iup.SetAttribute(search_list, "VALUE", "1")
				end

				return iup.DEFAULT
			end)

			-- Helper function to handle selection
			-- returns boolean indicating if the popup should be closed
			local function handle_selection(selected)
				if selected and selected > 0 then
					local original_index = map_table[selected]
					if original_index then
						if is_multiple then
							-- For multiple selection lists, need to handle VALUE differently
							local selection_string = string.rep("-", original_index - 1) .. "+" ..
								string.rep("-", #current_items - original_index)
							iup.SetAttribute(list_control, "VALUE", selection_string)
						else
							iup.SetAttribute(list_control, "VALUE", original_index)
						end
						-- Manually trigger the VALUECHANGED_CB
						local callback = iup.GetCallback(list_control, "VALUECHANGED_CB")
						if callback ~= nil then
							callback(list_control)
						end
					end
					return true
				end
				return false
			end

			-- Set up list double click callback
			iup.SetCallback(search_list, "DBLCLICK_CB", function(ih)
				table.insert(dialog_callbacks, ih)
				local selected = iup.GetInt(search_list, "VALUE")
				return handle_selection(selected) and iup.CLOSE or iup.DEFAULT
			end)

			-- Set up Enter key callback for search list
			iup.SetCallback(dialog, "K_ANY", iup.cb.k_any(function(ih, c)
				table.insert(dialog_callbacks, ih)
				if c == iup.K_CR then -- Enter key
					local selected = iup.GetInt(search_list, "VALUE")
					return handle_selection(selected) and iup.CLOSE or iup.DEFAULT
				elseif c == iup.K_ESC then -- Esc key
					return iup.CLOSE
				elseif c == iup.K_UP then -- Up arrow key
					local current = iup.GetInt(search_list, "VALUE")
					if current > 0 then
						local count = iup.GetInt(search_list, "COUNT")
						if current > 1 then
							iup.SetAttribute(search_list, "VALUE", current - 1)
						end
					end
				elseif c == iup.K_DOWN then -- Down arrow key
					local current = iup.GetInt(search_list, "VALUE")
					if current > 0 then
						local count = iup.GetInt(search_list, "COUNT")
						if current < count then
							iup.SetAttribute(search_list, "VALUE", current + 1)
						end
					end
				end
				return iup.DEFAULT
			end))

			-- Set up OK button callback
			iup.SetCallback(ok_button, "ACTION", function(ih)
				table.insert(dialog_callbacks, ih)
				local selected = iup.GetInt(search_list, "VALUE")
				return handle_selection(selected) and iup.CLOSE or iup.DEFAULT
			end)

			-- Show dialog
			iup.Popup(dialog, iup.CENTER, iup.CENTER)

			-- Popup closes, free callbacks
			iup.FreeCallbacks(dialog_callbacks)

			iup.SetFocus(search_input)
		elseif c == iup.XKeyCtrl(iup.K_C) then -- Ctrl+C
			-- Get all items from the list
			local items = {}
			local count = iup.GetInt(list_control, "COUNT")
			for i = 1, count do
				local item = iup.GetAttribute(list_control, tostring(i))
				if item then
					table.insert(items, item)
				end
			end

			-- Join items with newlines and copy to clipboard
			local clbd = iup.clipboard()
			if clbd then
				iup.SetAttribute(clbd, "TEXT", table.concat(items, "\n"))
			end
		elseif is_multiple and c == iup.XKeyCtrl(iup.K_A) then -- Ctrl+A: select all
			local count = iup.GetInt(list_control, "COUNT")
			if count > 0 then
				local all_selected = string.rep("+", count)
				iup.SetAttribute(list_control, "VALUE", all_selected)
			end
		end
		return iup.DEFAULT
	end
end

function M.list(items, value, attrs)
	local ret = iup.list(nil)
	if items then
		for i, v in ipairs(items) do
			iup.SetAttribute(ret, tostring(i), v)
		end
	end
	if value then
		iup.SetAttribute(ret, "VALUE", value)
	end
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end

	-- Add key press callback for Ctrl+F
	iup.SetCallback(ret, "K_ANY", iup.cb.k_any(create_keypress_callback(ret, attrs and attrs.MULTIPLE == "YES")))

	return ret
end

function M.select(items, value, attrs)
	local ret = iup.list(nil)
	if items then
		for i, v in ipairs(items) do
			iup.SetAttribute(ret, tostring(i), v)
		end
	end
	if value then
		iup.SetAttribute(ret, "VALUE", value)
	end
	iup.SetAttribute(ret, "EXPAND", "HORIZONTAL")
	iup.SetAttribute(ret, "DROPDOWN", "YES")
	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(ret, k, v)
		end
	end

	-- Add key press callback for Ctrl+F
	iup.SetCallback(ret, "K_ANY", iup.cb.k_any(create_keypress_callback(ret, attrs and attrs.MULTIPLE == "YES")))

	return ret
end

M.apply_button_color = "#256128"
M.apply_exit_button_color = "#C41E3A"
M.onetime_change_label_color = "#CC6402"
M.non_editable_input_bg_color = "#F0F0F0"
-- M.special_color = "#0F52BA" -- blue

return M
