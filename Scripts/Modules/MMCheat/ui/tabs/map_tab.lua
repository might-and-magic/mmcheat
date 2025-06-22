local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local prompt = require("MMCheat/ui/components/prompt")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local system = require("MMCheat/util/general/system")
local settings = require("MMCheat/util/settings")
local draw = require("MMCheat/util/image/draw")
local defaultcoords = require("MMCheat/data/defaultcoords")
local modlist = require("MMCheat/data/index")

for _, mod_name in ipairs(modlist) do
	local new_list = require("MMCheat/data/" .. mod_name .. "_defaultcoords")
	for k, v in pairs(new_list) do
		defaultcoords[k] = v
	end
end

local stop_process_executed = false

local angle_diagram_size = 25

local map_dot_rgb = { 255, 0, 0 }
local map_dot_size = 6

local M = {}

local map_select, bookmark_select, coord_x, coord_y, coord_z, direction, look_angle, copy_button, paste_button, reset_button_your_current, reset_button_map_default, ok_button, reveal_button, open_doors_button, kill_creatures_button, respawn_button, remove_bookmark_button, set_bookmark_button, add_bookmark_button, move_up_bookmark_button, move_down_bookmark_button, char_select, beacon_select, remove_beacon_button, set_beacon_button, days, hours, minutes

local angle_diagram_d, angle_diagram_a, coord_map_obj

-- Table to store bookmark coordinates (array of {X, Y, Z, Direction, LookAngle, Name})
local bookmark_coords

function M.cleanup()
	map_select, bookmark_select, coord_x, coord_y, coord_z, direction, look_angle, copy_button, paste_button, reset_button_your_current, reset_button_map_default, ok_button, reveal_button, open_doors_button, kill_creatures_button, respawn_button, remove_bookmark_button, set_bookmark_button, add_bookmark_button, move_up_bookmark_button, move_down_bookmark_button, char_select, beacon_select, remove_beacon_button, set_beacon_button, days, hours, minutes =
		nil

	angle_diagram_d, angle_diagram_a, coord_map_obj = nil

	bookmark_coords = nil
end

local function update_coord_map()
	coord_map_obj:load_map(iup.GetInt(map_select, "VALUE"))
	coord_map_obj:draw_dot_by_coords(iup.GetInt(coord_x, "VALUE") or 0, iup.GetInt(coord_y, "VALUE") or 0)
end

-- Get coordinate table or text from input fields
local function get_coordinates(use_table)
	local selected_index = iup.GetInt(map_select, "VALUE")
	local name = utils.mapconv.index_to_filename(selected_index)
	local x = iup.GetInt(coord_x, "VALUE") or 0
	local y = iup.GetInt(coord_y, "VALUE") or 0
	local z = iup.GetInt(coord_z, "VALUE") or 0
	local dir = iup.GetInt(direction, "VALUE") or 0
	local angle = iup.GetInt(look_angle, "VALUE") or 0

	local coord = {
		X = x,
		Y = y,
		Z = z,
		Direction = dir,
		LookAngle = angle,
		Name = name,
	}

	if use_table then
		return coord
	end

	return utils.format_coordinate_text(coord)
end

-- Parse and set coordinates to input fields
local function set_coordinates(coord_text_or_coord)
	local coord = coord_text_or_coord
	if type(coord_text_or_coord) == "string" then
		coord = utils.extract_coordinate_values(coord_text_or_coord)
	end

	local x = coord.X
	local y = coord.Y
	local z = coord.Z
	local dir = coord.Direction
	local angle = coord.LookAngle
	local name = coord.Name

	if x then
		iup.SetAttribute(coord_x, "VALUE", x)
	end
	if y then
		iup.SetAttribute(coord_y, "VALUE", y)
	end
	if z then
		iup.SetAttribute(coord_z, "VALUE", z)
	end
	if dir then
		iup.SetAttribute(direction, "VALUE", dir)
		angle_diagram_d:draw_line(dir or 0)
	end
	if angle then
		iup.SetAttribute(look_angle, "VALUE", angle)
		angle_diagram_a:draw_line(angle or 0)
	end
	if name and map_select then
		iup.SetAttribute(map_select, "VALUE", utils.mapconv.filename_to_index(name))
	end
	if x or y or name then
		update_coord_map()
	end
end

local function reset_coordinates()
	set_coordinates({
		X = Party.X,
		Y = Party.Y,
		Z = Party.Z,
		Direction = Party.Direction,
		LookAngle = Party.LookAngle,
		Name = Map.Name,
	})
end

local function set_inputs_from_bookmark_selected()
	local selected = iup.GetInt(bookmark_select, "VALUE")
	if selected and selected > 0 then -- Skip if blank is selected
		local coord = bookmark_coords[selected]
		if coord then
			set_coordinates(coord)
		end
	end
end

-- With latest bookmark_coords, write ini file, reload bookmark_select, properly select the entry, and set input fields from selected entry
-- selection: if -1, select the last entry instead of the previously selected entry in bookmark_select
local function refresh_with_bookmark_coords(selection)
	utils.write_coords_txt(bookmark_coords)
	local bookmark_items = {}
	for i, coord in ipairs(bookmark_coords) do
		bookmark_items[i] = utils.format_coordinate_text(coord, "bookmark_display")
	end
	local sel
	if selection == -1 then
		sel = #bookmark_coords
	elseif not selection then
		sel = true
	else
		sel = selection
	end
	utils.load_select_options(bookmark_select, bookmark_items, true, { sel, -1 })
	set_inputs_from_bookmark_selected()
end

-- Helper function to convert beacon to coord format
local function beacon_to_coord(beacon)
	return {
		X = beacon.X,
		Y = beacon.Y,
		Z = beacon.Z,
		Direction = beacon.Direction,
		LookAngle = beacon.LookAngle,
		Name = beacon.Map,
	}
end

-- Helper function to convert coord to beacon format
local function coord_to_beacon(coord, beacon)
	beacon.X = coord.X
	beacon.Y = coord.Y
	beacon.Z = coord.Z
	beacon.Direction = coord.Direction
	beacon.LookAngle = coord.LookAngle
	beacon.Map = coord.Name
end

-- Load beacon_select options for the currently selected character
local function load_beacon_select(selection)
	local char_index = iup.GetInt(char_select, "VALUE") - 1
	if not char_index or char_index < 0 then
		return
	end

	local char = Party.PlayersArray[char_index]
	if not char then
		return
	end

	local beacon_items = {}
	for i = 0, 4 do
		local beacon = char.Beacons[i]
		if beacon.ExpireTime < Game.Time then
			beacon_items[i + 1] = i18n._("empty")
		else
			local coord = beacon_to_coord(beacon)
			if coord and coord.Name then
				beacon_items[i + 1] = utils.format_coordinate_text(coord, "mapname_and_short")
			else
				beacon_items[i + 1] = i18n._("empty")
			end
		end
	end

	utils.load_select_options(beacon_select, beacon_items, true, selection)
end

-- Set inputs from the currently selected beacon
local function set_inputs_from_beacon_selected()
	local char_index = iup.GetInt(char_select, "VALUE") - 1
	local beacon_index = iup.GetInt(beacon_select, "VALUE") - 1

	if not char_index or char_index < 0 or not beacon_index or beacon_index < 0 then
		return
	end

	local char = Party.PlayersArray[char_index]
	if not char then
		return
	end

	local beacon = char.Beacons[beacon_index]
	if beacon.ExpireTime < Game.Time then
		-- Empty beacon, clear time inputs but not coordinates
		iup.SetAttribute(days, "VALUE", "0")
		iup.SetAttribute(hours, "VALUE", "0")
		iup.SetAttribute(minutes, "VALUE", "0")
	else
		-- Set coordinates from beacon
		local coord = beacon_to_coord(beacon)
		set_coordinates(coord)

		-- Set time inputs
		local time_remaining = beacon.ExpireTime - Game.Time
		if time_remaining > 0 then
			local time_components = utils.timestamp_to_time(time_remaining, true)
			iup.SetAttribute(days, "VALUE", tostring(time_components.days or 0))
			iup.SetAttribute(hours, "VALUE", tostring(time_components.hours or 0))
			iup.SetAttribute(minutes, "VALUE", tostring(time_components.minutes or 0))
		else
			iup.SetAttribute(days, "VALUE", "0")
			iup.SetAttribute(hours, "VALUE", "0")
			iup.SetAttribute(minutes, "VALUE", "0")
		end
	end
end

function M.reload()
	utils.load_select_options(char_select, utils.get_char_name_array(), true, true)
end

local function set_to_map_default_coords(map_index)
	local map_filename = utils.mapconv.index_to_filename(map_index)
	map_filename = utils.normalize_map_filename(map_filename:match("(.+)%..+$"))
	local default = defaultcoords[map_filename]
	if not default then
		default = {
			X = 0,
			Y = 0,
			Z = 0,
			Direction = 0,
		}
	end
	default.LookAngle = 0
	set_coordinates(default)
end

function M.firstload()
	-- Initialize map tables
	bookmark_coords = {}
	utils.mapconv.init()

	utils.load_select_options(map_select, utils.mapconv.map_select_options)

	iup.SetCallback(map_select, "VALUECHANGED_CB", function()
		local map_index = iup.GetInt(map_select, "VALUE")
		set_to_map_default_coords(map_index)
		return iup.DEFAULT
	end)

	-- Set current map, position and orientation
	reset_coordinates()

	-- Load bookmarks from coords.txt
	local coords = utils.read_coords_txt() -- coords could be 0-length {}
	local unique_coords = utils.dedup_coords(coords)
	if #unique_coords ~= #coords then   -- dup in the file, write the unique coords back to the file
		utils.write_coords_txt(unique_coords)
	end
	local bookmark_items = {}
	for i, coord in ipairs(unique_coords) do
		bookmark_items[i] = utils.format_coordinate_text(coord, "bookmark_display")
		bookmark_coords[i] = coord
	end
	-- Set
	utils.load_select_options(bookmark_select, bookmark_items, false, 0) -- Select 0 (blank) by default

	------------------ Go To frame callbacks ------------------
	iup.SetCallback(copy_button, "ACTION", function()
		local coord_text = get_coordinates()
		local clbd = iup.clipboard()
		if not clbd then
			return iup.DEFAULT
		end
		iup.SetAttribute(clbd, "TEXT", coord_text)
		return iup.DEFAULT
	end)

	iup.SetCallback(paste_button, "ACTION", function()
		local clbd = iup.clipboard()
		if not clbd then
			return iup.DEFAULT
		end
		local clipboard = iup.GetAttribute(clbd, "TEXT")
		if clipboard then
			set_coordinates(clipboard)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(reset_button_your_current, "ACTION", function()
		reset_coordinates()
		return iup.DEFAULT
	end)

	iup.SetCallback(reset_button_map_default, "ACTION", function()
		local map_index = iup.GetInt(map_select, "VALUE")
		set_to_map_default_coords(map_index)
		return iup.DEFAULT
	end)

	iup.SetCallback(ok_button, "ACTION", function()
		local coord = get_coordinates(true)
		local current_map = Map.Name
		if utils.compare_map_filename(coord.Name, current_map) then
			coord.Name = nil
		end
		if
			settings.get_setting("stop_other_proc_before_first_go_to") == "true"
			and coord.Name
			and not stop_process_executed
		then
			system.stop_other_processes("mm" .. Game.Version .. ".exe")
			stop_process_executed = true
		end
		evt.MoveToMap(coord)
		return iup.CLOSE
	end)

	iup.SetCallback(coord_x, "VALUECHANGED_CB", function()
		update_coord_map()
		return iup.DEFAULT
	end)

	iup.SetCallback(coord_y, "VALUECHANGED_CB", function()
		update_coord_map()
		return iup.DEFAULT
	end)

	local function update_angle_d_diagram()
		angle_diagram_d:draw_line(iup.GetInt(direction, "VALUE") or 0)
	end

	local function update_angle_a_diagram()
		angle_diagram_a:draw_line(iup.GetInt(look_angle, "VALUE") or 0)
	end

	iup.SetCallback(direction, "VALUECHANGED_CB", function()
		update_angle_d_diagram()
		return iup.DEFAULT
	end)

	iup.SetCallback(look_angle, "VALUECHANGED_CB", function()
		update_angle_a_diagram()
		return iup.DEFAULT
	end)

	coord_map_obj.image_label_obj:add_button_cb(function(ih, button, pressed, x, y, status)
		local x_bitmap = x
		local y_bitmap = utils.map_image_size - y -- flip y axis as y here is top-left origin
		if iup.IsButton1(status) and pressed == 1 then
			local x_coord, y_coord = coord_map_obj:bitmap_to_coords(x_bitmap, y_bitmap)
			iup.SetAttribute(coord_x, "VALUE", x_coord)
			iup.SetAttribute(coord_y, "VALUE", y_coord)
			update_coord_map()
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(
		angle_diagram_d.label,
		"BUTTON_CB",
		iup.cb.button_cb(function(ih, button, pressed, x, y, status)
			if iup.IsButton1(status) and pressed == 1 then
				local angle = draw.coords_to_angle(x, y, angle_diagram_size)
				iup.SetAttribute(direction, "VALUE", angle)
				update_angle_d_diagram()
			end
			return iup.DEFAULT
		end)
	)

	iup.SetCallback(
		angle_diagram_a.label,
		"BUTTON_CB",
		iup.cb.button_cb(function(ih, button, pressed, x, y, status)
			if iup.IsButton1(status) and pressed == 1 then
				local angle = draw.coords_to_angle(x, y, angle_diagram_size, true)
				iup.SetAttribute(look_angle, "VALUE", angle)
				update_angle_a_diagram()
			end
			return iup.DEFAULT
		end)
	)

	------------------ Bookmarked Coordinates frame callbacks ------------------
	iup.SetCallback(bookmark_select, "VALUECHANGED_CB", function()
		set_inputs_from_bookmark_selected()
		return iup.DEFAULT
	end)

	iup.SetCallback(remove_bookmark_button, "ACTION", function()
		local selected = iup.GetInt(bookmark_select, "VALUE")
		if selected and selected > 0 then -- Don't remove if blank is selected
			local coord = bookmark_coords[selected]
			local label_text =
				i18n._("confirm_remove_bookmark", utils.format_coordinate_text(coord, "bookmark_display"))
			local choice = iup.Alarm(i18n._("confirmation"), label_text, i18n._("yes"), i18n._("no"))
			if choice == 1 then -- Yes
				table.remove(bookmark_coords, selected)
				refresh_with_bookmark_coords()
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(set_bookmark_button, "ACTION", function()
		local selected = iup.GetInt(bookmark_select, "VALUE")
		if selected and selected > 0 then -- Don't set if blank is selected
			local coord = get_coordinates(true)
			local old_coord = bookmark_coords[selected]
			local old_comment = old_coord.Comment
			local label_text = i18n._(
				"replace_bookmark_with_comment",
				utils.format_coordinate_text(old_coord, "bookmark_display"),
				utils.format_coordinate_text(coord, "short_and_mapname")
			)
			local default_new_comment = old_comment and old_comment ~= "" and old_comment
				or utils.mapconv.filename_to_name(coord.Name)
			local new_comment = prompt(i18n._("enter_comment"), label_text, default_new_comment)
			if new_comment == nil then -- cancel, do not proceed
				return iup.DEFAULT
			end
			if new_comment == "" then -- empty, but proceed
				-- note `shallow_equal({}, {a=nil})` is true
				new_comment = nil
			end
			coord.Comment = new_comment
			if not utils.exists_in(bookmark_coords, coord) then -- Don't set if coord is exactly the same as one in bookmark_coords including itself
				bookmark_coords[selected] = coord
				refresh_with_bookmark_coords()
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(add_bookmark_button, "ACTION", function()
		local coord = get_coordinates(true)
		-- Don't add if coord is exactly the same as one in bookmark_coords
		local label_text = i18n._("add_bookmark_with_comment", utils.format_coordinate_text(coord, "short_and_mapname"))
		local mapname = utils.mapconv.filename_to_name(coord.Name)
		local new_comment = prompt(i18n._("enter_comment"), label_text, mapname)
		if new_comment == nil then -- cancel, do not proceed
			return iup.DEFAULT
		end
		if new_comment == "" then -- empty, but proceed
			-- note `shallow_equal({}, {a=nil})` is true
			new_comment = nil
		end
		coord.Comment = new_comment
		if not utils.exists_in(bookmark_coords, coord) then
			table.insert(bookmark_coords, coord)
			refresh_with_bookmark_coords(-1)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(move_up_bookmark_button, "ACTION", function()
		local selected = iup.GetInt(bookmark_select, "VALUE")
		if selected and selected > 0 then -- Don't move if blank is selected
			local new_index = utils.move_item(bookmark_coords, selected, true)
			if new_index then
				refresh_with_bookmark_coords(new_index)
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(move_down_bookmark_button, "ACTION", function()
		local selected = iup.GetInt(bookmark_select, "VALUE")
		if selected and selected > 0 then -- Don't move if blank is selected
			local new_index = utils.move_item(bookmark_coords, selected, false)
			if new_index then
				refresh_with_bookmark_coords(new_index)
			end
		end
		return iup.DEFAULT
	end)

	------------------ Lloyd's beacon frame callbacks ------------------
	-- Load character options for char_select
	utils.load_select_options(char_select, utils.get_char_name_array(), false, 0)

	-- Initialize beacon_select for first character
	if Party and Party.PlayersArray and #Party.PlayersArray > 0 then
		load_beacon_select(0)
		set_inputs_from_beacon_selected()
	end

	iup.SetCallback(char_select, "VALUECHANGED_CB", function()
		load_beacon_select(1)
		set_inputs_from_beacon_selected()
		return iup.DEFAULT
	end)

	iup.SetCallback(beacon_select, "VALUECHANGED_CB", function()
		set_inputs_from_beacon_selected()
		return iup.DEFAULT
	end)

	iup.SetCallback(remove_beacon_button, "ACTION", function()
		local char_index = iup.GetInt(char_select, "VALUE") - 1
		local beacon_index = iup.GetInt(beacon_select, "VALUE") - 1

		if char_index >= 0 and beacon_index >= 0 then
			local char = Party.PlayersArray[char_index]
			if char then
				char.Beacons[beacon_index].ExpireTime = 0
				load_beacon_select(true)
				set_inputs_from_beacon_selected()
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(set_beacon_button, "ACTION", function()
		local char_index = iup.GetInt(char_select, "VALUE") - 1
		local beacon_index = iup.GetInt(beacon_select, "VALUE") - 1

		if char_index >= 0 and beacon_index >= 0 then
			local char = Party.PlayersArray[char_index]
			if char then
				local coord = get_coordinates(true)
				local beacon = char.Beacons[beacon_index]

				-- Convert coord to beacon
				coord_to_beacon(coord, beacon)

				-- Set expire time
				local day_val = iup.GetInt(days, "VALUE") or 0
				local hour_val = iup.GetInt(hours, "VALUE") or 0
				local minute_val = iup.GetInt(minutes, "VALUE") or 0
				local duration = utils.time_to_timestamp(0, 0, day_val, hour_val, minute_val, 0, true)
				beacon.ExpireTime = Game.Time + duration

				load_beacon_select(true)
				set_inputs_from_beacon_selected()
			end
		end
		return iup.DEFAULT
	end)

	------------------ Current Map frame callbacks ------------------
	iup.SetCallback(reveal_button, "ACTION", function()
		if Map.IndoorOrOutdoor == 2 then
			-- Reveal entire current outdoor map
			for _, a in Map.VisibleMap1 do
				for i in a do
					a[i] = true
				end
			end
		else
			-- Reveal entire current indoor map
			for _, olItem in Map.Outlines.Items do
				olItem.Visible = true
			end
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(open_doors_button, "ACTION", function()
		-- Open all doors in the current map
		for _, door in Map.Doors do
			door.State = 1
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(kill_creatures_button, "ACTION", function()
		-- Kill all creatures in the current map and give experience
		local total_exp = 0
		for _, mon in Map.Monsters do
			if mon and mon.HP and mon.HP > 0 then
				mon.HP = 0
				total_exp = total_exp + mon.Exp
			end
		end
		Party.AddKillExp(total_exp)
		return iup.DEFAULT
	end)

	iup.SetCallback(respawn_button, "ACTION", function()
		-- Force a refill
		Map.LastRefillDay = 0
		return iup.DEFAULT
	end)
end

function M.create()
	------------------ Go To frame main components ------------------
	map_select = ui.select({})

	-- coord_x and coord_y: [-22528, 22528] for outdoor map. On a outdoor map, center point is X=0, Y=0, South West corner is X=-22528, Y=-22528, North East corner is X=22528, Y=22528, if you teleport to a point outside this range, the game will teleport you to the nearest point within this range
	coord_x = ui.int_input(0, {
		-- Here we allow all 16-bit signed integer
		SPINMIN = -32768,
		SPINMAX = 32767,
	})
	coord_y = ui.int_input(0, {
		-- Here we allow all 16-bit signed integer
		SPINMIN = -32768,
		SPINMAX = 32767,
	})
	-- coord_z: height. You can fly as high as 3000 in MM6, 4000 in MM7, this limit is different in different maps in MM8 and merge. However, you can teleport higher than the fly limit, but no higher than 8192 which is a hard limit, you'll go to 8192 if you teleport higher
	coord_z = ui.int_input(0, {
		SPINMIN = -8192,
		SPINMAX = 8192,
	})
	-- direction: 0 is East, 512 is North, 1024 is West, 1536 is South, when you try to go 2048, it returns to 0
	direction = ui.int_input(0, {
		SPINMIN = 0,
		SPINMAX = 2047,
	})
	-- look_angle: 0 is straight forward, 512 is 90 degrees up, -512 is 90 degrees down, mm8 (GrayFace 2.5+ with mouse look) has limits [-240, 300], mm6 and mm7 do not have limits and allows you to look any angle by teleporting, including upside down/180 degrees (1024), or more than 360 degrees (more than 2048) which is essentially the same as 0-360 degrees [0, 2047] but the game doesn't reset it to [0, 2047] or [-1023, 1024] like it does for `direction`
	look_angle = ui.int_input(0)

	local angle_diagram_a2_label = ui.label("→")
	angle_diagram_d = draw.AngleDiagram:new(angle_diagram_size, 1, { 0, 0, 0 }, { 255, 0, 0 })
	angle_diagram_a = draw.AngleDiagram:new(angle_diagram_size, 1, { 0, 0, 0 }, { 255, 0, 0 })

	copy_button = ui.button(i18n._("copy"), nil)
	paste_button = ui.button(i18n._("paste"), nil)
	reset_button_your_current = ui.button(i18n._("current_location"), nil)
	reset_button_map_default = ui.button(i18n._("map_default_location"), nil)
	ok_button = ui.button(i18n._("let_s_go"), nil, {
		FGCOLOR = ui.apply_exit_button_color,
		MINSIZE = "80x",
	})

	local go_to_frame_button_hbox = ui.button_hbox({ copy_button, paste_button })
	local go_to_frame_button_hbox2 = ui.button_hbox({ reset_button_your_current, reset_button_map_default, ok_button })

	local go_to_frame_main_content_vbox = ui.vbox({
		ui.hbox({ ui.label(i18n._("map")), map_select }),
		ui.hbox({
			ui.label(i18n._("coordinates")),
			ui.label(" X="),
			coord_x,
			ui.label("Y="),
			coord_y,
			ui.label("Z="),
			coord_z,
		}),
		ui.hbox({
			angle_diagram_d.label,
			ui.label(i18n._("direction")),
			direction,
			ui.label(i18n._("look_angle")),
			look_angle,
			angle_diagram_a.label,
			angle_diagram_a2_label,
		}),
		go_to_frame_button_hbox,
		go_to_frame_button_hbox2,
	}, {
		ALIGNMENT = "ACENTER",
	})

	------------------ Bookmarked coordinates frame ------------------
	bookmark_select = ui.select({})
	remove_bookmark_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "80x",
		FGCOLOR = ui.apply_button_color,
	})
	set_bookmark_button = ui.button(i18n._("set"), nil, {
		MINSIZE = "80x",
		FGCOLOR = ui.apply_button_color,
	})
	add_bookmark_button = ui.button(i18n._("add"), nil, {
		MINSIZE = "80x",
		FGCOLOR = ui.apply_button_color,
	})
	move_up_bookmark_button = ui.button("↑", nil, {
		MINSIZE = "20x",
		FGCOLOR = ui.apply_button_color,
		TIP = i18n._("move_up"),
	})
	move_down_bookmark_button = ui.button("↓", nil, {
		MINSIZE = "20x",
		FGCOLOR = ui.apply_button_color,
		TIP = i18n._("move_down"),
	})
	local bookmark_button_hbox = ui.button_hbox({
		remove_bookmark_button,
		set_bookmark_button,
		add_bookmark_button,
		move_up_bookmark_button,
		move_down_bookmark_button,
	})
	local bookmark_frame = ui.frame(
		i18n._("bookmarked_coordinates"),
		ui.vbox({ bookmark_select, bookmark_button_hbox }, {
			ALIGNMENT = "ACENTER",
		})
	)

	------------------ Lloyd's beacon frame ------------------
	char_select = ui.select({})
	beacon_select = ui.select({}, nil, {
		MINSIZE = "220x",
	})
	remove_beacon_button = ui.button(i18n._("remove"), nil, {
		MINSIZE = "80x",
		FGCOLOR = ui.apply_button_color,
	})
	set_beacon_button = ui.button(i18n._("set"), nil, {
		MINSIZE = "80x",
		FGCOLOR = ui.apply_button_color,
	})

	days = ui.uint_input(0, {
		ALIGNMENT = "ARIGHT",
	})
	hours = ui.uint_input(0, {
		SPINMAX = 23,
		ALIGNMENT = "ARIGHT",
	})
	minutes = ui.uint_input(0, {
		SPINMAX = 59,
		ALIGNMENT = "ARIGHT",
	})

	local beacon_select_hbox = ui.hbox({ char_select, beacon_select })
	local beacon_time_hbox = ui.hbox({
		days,
		ui.label(i18n._("days_shortname")),
		hours,
		ui.label(i18n._("hours_shortname")),
		minutes,
		ui.label(i18n._("minutes_shortname")),
	})
	local beacon_button_hbox = ui.hbox({ remove_beacon_button, set_beacon_button })

	local lloyds_beacon_local_name = utils.get_spell_local_name("LloydsBeacon")
	local beacon_frame = ui.frame(
		lloyds_beacon_local_name,
		ui.vbox({ beacon_select_hbox, beacon_time_hbox, beacon_button_hbox }, {
			ALIGNMENT = "ACENTER",
		})
	)

	------------------ Go To frame big container ------------------
	local go_to_frame_content_vbox = ui.vbox({ go_to_frame_main_content_vbox, bookmark_frame, beacon_frame }, {
		ALIGNMENT = "ACENTER",
	})

	coord_map_obj = draw.CoordMap:new(utils.map_image_size, map_dot_rgb, map_dot_size)

	local go_to_frame_all_hbox = ui.hbox({ go_to_frame_content_vbox, coord_map_obj.label }, {
		ALIGNMENT = "ACENTER",
	})

	local go_to_frame = ui.frame(i18n._("go_to"), go_to_frame_all_hbox)

	------------------ Jump frame ------------------
	local jump_frame
	if Game.Version == 8 then
		local jump_speed_input = ui.uint_input(1200, {
			ALIGNMENT = "ARIGHT",
		})
		local jump_button = ui.button(i18n._("jump"), nil, {
			MINSIZE = "80x",
			FGCOLOR = ui.apply_exit_button_color,
		})

		iup.SetCallback(jump_button, "ACTION", function()
			local speed = iup.GetInt(jump_speed_input, "VALUE") or 1200
			local dir = iup.GetInt(direction, "VALUE") or 512
			local angle = iup.GetInt(look_angle, "VALUE") or 256
			evt.Jump(dir, angle, speed)
			return iup.CLOSE
		end)

		local jump_hbox = ui.hbox({
			ui.label(i18n._("with_above_direction_and_angle")),
			ui.label(i18n._("speed")),
			jump_speed_input,
			jump_button,
		})
		jump_frame = ui.frame(i18n._("jump"), jump_hbox)
	end

	------------------ Town Portal frame ------------------
	local town_portal_frame, town_portal_and_jump_hbox_content, town_portal_and_jump_hbox

	if Game.Version ~= 6 then
		local activate_towns_button = ui.button(i18n._("activate_all_towns"), nil, {
			FGCOLOR = ui.apply_button_color,
		})
		local town_portal_buttons = { activate_towns_button }

		local function activate_towns_callback()
			utils.EnableAllTownPortalQbits()
			return iup.DEFAULT
		end

		iup.SetCallback(activate_towns_button, "ACTION", activate_towns_callback)

		local continental_travel_button
		if Merge ~= nil then
			continental_travel_button = ui.button(i18n._("set_next_cast_continental"), nil, {
				FGCOLOR = ui.apply_button_color,
			})
			table.insert(town_portal_buttons, continental_travel_button)

			local function continental_travel_callback()
				TownPortalControls.GenDimDoor()
				TownPortalControls.SwitchTo(4)
				return iup.DEFAULT
			end

			iup.SetCallback(continental_travel_button, "ACTION", continental_travel_callback)
		end

		local town_portal_button_hbox = ui.button_hbox(town_portal_buttons)

		local town_portal_local_name = utils.get_spell_local_name("TownPortal")
		town_portal_frame = ui.frame(town_portal_local_name, town_portal_button_hbox)

		town_portal_and_jump_hbox_content = {}

		if Game.Version == 8 then
			table.insert(town_portal_and_jump_hbox_content, jump_frame)
		end

		table.insert(town_portal_and_jump_hbox_content, town_portal_frame)

		town_portal_and_jump_hbox = ui.hbox(town_portal_and_jump_hbox_content)
	end

	------------------ Current Map frame ------------------
	reveal_button = ui.button(i18n._("reveal_map"), nil, {
		FGCOLOR = ui.apply_button_color,
	})
	open_doors_button = ui.button(i18n._("open_doors"), nil, {
		FGCOLOR = ui.apply_button_color,
	})
	kill_creatures_button = ui.button(i18n._("kill_creatures"), nil, {
		FGCOLOR = ui.apply_button_color,
	})
	respawn_button = ui.button(i18n._("force_respawn"), nil, {
		FGCOLOR = ui.apply_button_color,
	})

	local current_map_frame_button_hbox = ui.button_hbox({
		reveal_button,
		open_doors_button,
		kill_creatures_button,
		respawn_button,
	})

	local current_map_frame = ui.frame(i18n._("current_map"), current_map_frame_button_hbox)

	------------------ Main container ------------------
	local all_content = { go_to_frame }
	if Game.Version ~= 6 then
		table.insert(all_content, town_portal_and_jump_hbox)
	end
	table.insert(all_content, current_map_frame)

	return ui.vbox(all_content, {
		TABTITLE = i18n._("map"),
		ALIGNMENT = "ACENTER",
	})
end

return M
