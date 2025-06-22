local iup = require("iup")
local bitmap = require("MMCheat/util/image/bitmap")
local mmimage = require("MMCheat/util/image/mmimage")
local i18n = require("MMCheat/i18n/i18n")
local ui = require("MMCheat/ui/components/ui_components")
local system = require("MMCheat/util/general/system")
local indoor2dmap = require("MMCheat/util/image/indoor2dmap")
local utils = require("MMCheat/util/utils")

local ImageLabel = {}
ImageLabel.__index = ImageLabel

--[[
    ImageLabel:new

    Constructs a new ImageLabel instance.

    This class creates a labeled image widget using the IUP GUI toolkit. It supports 24-bit (RGB)
    and 32-bit (RGBA) pixel data, allowing dynamic pixel loading, optional context menus, and event callbacks.

    Parameters (passed as a table `params`):

    - width (number):         Width of the image in pixels. Required.
    - height (number):        Height of the image in pixels. Required.
    - pixels (table):         A flat array of pixel values (either RGB or RGBA). Required.
                              Each pixel is usually represented as a sequence of bytes.
    - attrs (table):          Optional table of additional IUP label attributes to apply (e.g., "BGCOLOR", "EXPAND").
    - use_context_menu (boolean): Optional IUP menu to show when right-clicking the label.
                              Defaults to `true`, meaning context menu will be initialized automatically.
                              Set to `false` to disable context menu entirely.
    - use_handle (boolean):   If true, assigns a unique handle name (`self.handle_name`) to this label
                              for later retrieval using IUP’s handle system.
    - alt_pixels_to_save (any): Optional alternative pixel data.

    Returns:
        A new ImageLabel instance with pixel data loaded and an optional context menu on right-click.

    Notes:
    - Only 24-bit (RGB) and 32-bit (RGBA) images are supported, 8-bit is not supported.
    - The context menu (if enabled) appears on mouse button 3 (right-click) only when `self.pixels` is not nil.
]]
function ImageLabel:new(params)
	local width = params.width
	local height = params.height
	local pixels = params.pixels
	local attrs = params.attrs
	local use_context_menu = params.use_context_menu ~= nil and params.use_context_menu or true -- defaults to true
	local use_handle = params.use_handle
	local alt_pixels_to_save = params.alt_pixels_to_save
	local use_svg = params.use_svg
	local info = params.info or {}

	local self = setmetatable({}, ImageLabel)
	self.width = width
	self.height = height
	self.pixels = pixels
	self.use_context_menu = use_context_menu
	self.iup_image = nil
	self.use_svg = use_svg
	self.info = info

	self.callbacks = {}

	-- Create label
	self.label = iup.label()
	iup.SetAttribute(self.label, "ALIGNMENT", "ACENTER")

	if attrs then
		for k, v in pairs(attrs) do
			iup.SetAttribute(self.label, k, v)
		end
	end

	if use_handle then
		local unique_handle_name = "img_lbl_" .. tostring(self.label):match(": (0x%x+)")
		self.handle_name = unique_handle_name
	end

	-- Load initial image
	self:load_pixels(width, height, self.pixels)

	-- Setup context menu
	self:_init_context_menu()

	-- Setup right-click callback (button 3)
	iup.SetCallback(self.label, "BUTTON_CB", iup.cb.button_cb(
		function(ih, button, pressed, x, y, status)
			-- if self.pixels is nil, don't show context menu as the menu is for saving image
			if self.use_context_menu and self.pixels and iup.IsButton3(status) and pressed == 0 then
				iup.Popup(self._context_menu, iup.MOUSEPOS, iup.MOUSEPOS)
			end
			if self.callbacks["BUTTON_CB"] then
				return self.callbacks["BUTTON_CB"](self.label, button, pressed, x, y, status)
			end
			return iup.DEFAULT
		end))

	return self
end

function ImageLabel:destroy()
	iup.Destroy(self.label)
end

function ImageLabel:_load_iup_image(iup_image)
	-- Internal use only, should not skip self.pixels = pixels
	if not iup_image then
		return
	end
	if self.iup_image then
		iup.Destroy(self.iup_image)
	end
	self.iup_image = iup_image
	if self.handle_name then
		local img = iup.GetHandle(self.handle_name)
		if img then
			iup.Destroy(img)
		end
		iup.SetHandle(self.handle_name, iup_image)
		iup.SetAttribute(self.label, "IMAGE", self.handle_name)
	else
		iup.SetAttributeHandle(self.label, "IMAGE", iup_image)
	end
	collectgarbage("collect")
end

-- Load new pixels into image
function ImageLabel:load_pixels(width, height, pixels)
	if not width then
		width = self.width
	end
	if not height then
		height = self.height
	end
	if not pixels or #pixels == 0 then
		pixels = nil
	end

	self.width = width
	self.height = height
	self.pixels = pixels

	-- when self.pixels = nil, it means the image is transparent (rgba)
	local is_rgb = pixels and #pixels == 3 * width * height
	local iup_image_func = is_rgb and iup.imagergb or iup.imagergba

	local image = iup_image_func(width, height, pixels)
	self:_load_iup_image(image)
end

function ImageLabel:load_bmp_file(filename)
	local info = bitmap.bmp_file_to_pixel_data_flat_rgba(filename)
	if not info then
		self:load_pixels()
		return
	end
	self:load_pixels(info.width, info.height, info.pixels)
end

-- MM specific
function ImageLabel:load_mm_bitmap_filename(filename, transparent_color, cut)
	local bitmap_info = mmimage.get_bitmap_info_by_filename(filename)
	if not bitmap_info then
		self:load_pixels()
		return
	end
	local width = bitmap_info.Width
	local height = bitmap_info.Height
	local pixels = mmimage.mem_to_bmp_pixel_data_flat_rgb(bitmap_info, cut)
	if transparent_color then
		pixels = bitmap.rgb_to_rgba_with_transparency(pixels, transparent_color)
	end
	self:load_pixels(width, height, pixels)
	self:set_filename(filename)
end

-- Set a single attribute
function ImageLabel:set_attr(key, value)
	iup.SetAttribute(self.label, key, value)
end

-- Set multiple attributes
function ImageLabel:set_attrs(attr_table)
	for k, v in pairs(attr_table) do
		iup.SetAttribute(self.label, k, v)
	end
end

function ImageLabel:set_filename(filename)
	self.info.filename = filename
end

function ImageLabel:set_map_xy(map_xy)
	self.info.map_x_min = map_xy.x_min
	self.info.map_x_max = map_xy.x_max
	self.info.map_y_min = map_xy.y_min
	self.info.map_y_max = map_xy.y_max
end

-- Add a BUTTON_CB without overriding context menu, can add only once
function ImageLabel:add_button_cb(func)
	self.callbacks["BUTTON_CB"] = func
end

-- Initialize right-click context menu
function ImageLabel:_init_context_menu()
	local item_save = iup.item(i18n._("save_image"))
	local item_info = iup.item(i18n._("image_info"))
	self._context_menu = iup.menu(item_save, item_info)

	iup.SetCallback(item_save, "ACTION", function()
		local filedlg = iup.filedlg()

		iup.SetAttribute(filedlg, "DIALOGTYPE", "SAVE")
		iup.SetAttribute(filedlg, "TITLE", i18n._("save_image"))

		local default_filename = ""
		if self.info.filename and self.info.filename ~= "" then
			default_filename = self.info.filename
		else
			default_filename = "image"
		end
		local extfilter
		if self.use_svg then
			default_filename = default_filename .. ".svg"
			extfilter = "SVG (*.svg)|*.svg|BMP (*.bmp)|*.bmp"
		else
			default_filename = default_filename .. ".bmp"
			extfilter = "BMP (*.bmp)|*.bmp"
		end
		iup.SetAttribute(filedlg, "FILE", default_filename)
		iup.SetAttribute(filedlg, "EXTFILTER", extfilter)

		iup.Popup(filedlg, iup.CENTER, iup.CENTER)
		local status = iup.GetInt(filedlg, "STATUS")
		if status == 0 or status == 1 then -- 0: Normal, existing file; 1: New file; -1: Cancelled
			local filepath = iup.GetAttribute(filedlg, "VALUE")
			local filename = filepath:match("[^\\/]+$")
			local dir = utils.get_dir(filepath)
			-- Select any *NWC* dungeon map, right click and save image, and type "@allindoorsvg" / "@allindoorbmp" / "@alloutdoorbmp" (possible to add args) as file name and save, MMCheat will save all these maps in that format in the selected directory
			if self.info.filename and (self.info.filename:lower() == "d50" or self.info.filename:lower():find("nwc", 1, true)) then
				local lower_filename = filename:lower()
				mmimage.export_all_maps(dir, lower_filename)
				return iup.DEFAULT
			end
			local ext = (filepath:match("%.([^%.\\/]+)$") or ""):lower()
			local path_without_ext = filepath:match("^(.*)%.[^%.\\/]+$") or filepath
			local filename_without_ext = filename:match("^(.*)%.[^%.]+$") or filename
			local final_type
			if self.use_svg then
				local selected = iup.GetInt(filedlg, "FILTERUSED")
				local selected_ext
				if selected == 1 then
					selected_ext = "svg"
				elseif selected == 2 then
					selected_ext = "bmp"
				end
				if selected_ext == ext then
					final_type = selected_ext
				else
					local choice = iup.Alarm(i18n._("warning"), i18n._("save_as_svg_or_bmp",
						filename_without_ext .. ".svg", filename_without_ext .. ".bmp"), "SVG", "BMP", i18n._("cancel")) -- 0: Cancel; 1: SVG; 2: BMP; 3: Cancel
					if choice == 1 then
						final_type = "svg"
					elseif choice == 2 then
						final_type = "bmp"
					end
				end
			else
				final_type = "bmp"
			end
			if not final_type then
				return iup.DEFAULT
			end
			local final_filepath = path_without_ext .. "." .. final_type
			if final_type == "svg" then
				local svg = indoor2dmap.get_map_svg(self.info.filename)
				system.save_text_file(final_filepath, svg)
			elseif final_type == "bmp" then
				local pixels_to_save = self.alt_pixels_to_save or self.pixels
				bitmap.save_image_to_bmp_file(final_filepath, pixels_to_save, self.width, self.height)
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(item_info, "ACTION", function()
		local info_table = {}
		if self.info.filename then
			table.insert(info_table, i18n._("file_name") .. i18n._("colon") .. self.info.filename)
		end
		table.insert(info_table, i18n._("image_size") .. i18n._("colon") .. self.width .. " x " .. self.height)
		if self.info.map_x_min and self.info.map_x_max and self.info.map_y_min and self.info.map_y_max then
			table.insert(info_table, i18n._("map_x") .. i18n._("colon") .. "[" .. self.info.map_x_min .. ", " ..
				self.info.map_x_max .. "]")
			table.insert(info_table, i18n._("map_y") .. i18n._("colon") .. "[" .. self.info.map_y_min .. ", " ..
				self.info.map_y_max .. "]")
			table.insert(info_table,
				i18n._("map_size") .. i18n._("colon") .. (self.info.map_x_max - self.info.map_x_min) .. " x " ..
				(self.info.map_y_max - self.info.map_y_min))
		end
		local info_multiline = ui.multiline(table.concat(info_table, "\n"), {
			SIZE = "160x",
			VISIBLELINES = 6,
			READONLY = "YES"
		})
		local ok_button = ui.button(i18n._("ok"), nil, {
			MINSIZE = "80x"
		})
		local dialog_callbacks = {}
		iup.SetCallback(ok_button, "ACTION", function(ih)
			table.insert(dialog_callbacks, ih)
			return iup.CLOSE
		end)
		local info_vbox = ui.vbox({ info_multiline, ok_button }, {
			ALIGNMENT = "ACENTER"
		})
		local info_dlg = ui.dialog({ info_vbox }, {
			TITLE = i18n._("image_info"),
			BRINGFRONT = "YES"
		})
		iup.Popup(info_dlg, iup.CENTER, iup.CENTER)
		iup.FreeCallbacks(dialog_callbacks)
		return iup.DEFAULT
	end)
end

function ImageLabel:set_alt_pixels_to_save(pixels)
	self.alt_pixels_to_save = pixels
end

function ImageLabel:set_use_context_menu(use_context_menu)
	self.use_context_menu = use_context_menu
end

function ImageLabel:set_use_svg(use_svg)
	self.use_svg = use_svg
end

return ImageLabel
