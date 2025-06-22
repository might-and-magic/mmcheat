local ui = require("MMCheat/ui/components/ui_components")
local iup = require("iup")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local mmimage = require("MMCheat/util/image/mmimage")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")

local M = {}

local terra_image_label_obj, timestamp, score, date_select, month_select, year, hour, minute, tick, moonphase,
dayoftheweek, game_start_button, spring_equinox_button, summer_solstice_button, autumnal_equinox_button,
winter_solstice_button, apply_button, reset_button, snow_checkbox, rain_checkbox, fog_checkbox,
weather_apply_button, weather_reset_button

function M.cleanup()
	terra_image_label_obj, timestamp, score, date_select, month_select, year, hour, minute, tick, moonphase,
	dayoftheweek, game_start_button, spring_equinox_button, summer_solstice_button, autumnal_equinox_button,
	winter_solstice_button, apply_button, reset_button, snow_checkbox, rain_checkbox, fog_checkbox,
	weather_apply_button, weather_reset_button = nil
end

local function update_timestamp_display(year, month, date, hour, minute, tick, timestamp_input)
	local ticks = utils.time_to_timestamp(year, month, date, hour, minute, tick)
	iup.SetAttribute(timestamp_input, "VALUE", ticks)
end

local function update_moon_phase(date_val, moonphase_input)
	iup.SetAttribute(moonphase_input, "VALUE", utils.date_to_moonphase(date_val))
end

local function update_day_of_week(date_val, dayoftheweek_input)
	iup.SetAttribute(dayoftheweek_input, "VALUE", utils.date_to_dayofweek(date_val))
end

local function update_score(timestamp_val, score_input)
	iup.SetAttribute(score_input, "VALUE", utils.get_score(timestamp_val))
end

local function update_inputs_from_timestamp(timestamp_val, date, month_select, year, hour, minute, tick, moonphase,
											dayoftheweek, score)
	local time = utils.timestamp_to_time(timestamp_val)

	iup.SetAttribute(date, "VALUE", time.days)
	iup.SetAttribute(month_select, "VALUE", time.months)
	iup.SetAttribute(year, "VALUE", time.years)
	iup.SetAttribute(hour, "VALUE", time.hours)
	iup.SetAttribute(minute, "VALUE", time.minutes)
	iup.SetAttribute(tick, "VALUE", time.ticks)

	update_moon_phase(time.days, moonphase)
	update_day_of_week(time.days, dayoftheweek)
	update_score(timestamp_val, score)
end

function M.reload()
	update_score(iup.GetInt(timestamp, "VALUE") or 0, score)
end

function M.firstload()
	local date_select_table = {}
	for i = 1, 28 do
		date_select_table[#date_select_table + 1] = i
	end
	utils.load_select_options(date_select, date_select_table)

	local function update_terra_image(timestamp)
		local terra_image_filename = mmimage.get_terra_filename_by_timestamp(timestamp)
		terra_image_label_obj:load_mm_bitmap_filename(terra_image_filename)
	end

	-- Function to update all inputs from current game time
	local function update_from_game_time()
		local current_ticks = Game.Time
		update_inputs_from_timestamp(current_ticks, date_select, month_select, year, hour, minute, tick, moonphase,
			dayoftheweek, score)
		iup.SetAttribute(timestamp, "VALUE", current_ticks)
		update_terra_image(current_ticks)
	end

	-- Event handler for input changes
	local function on_input_change()
		local date_val = iup.GetInt(date_select, "VALUE") or 1
		local month_val = iup.GetInt(month_select, "VALUE") or 1
		local year_val = iup.GetInt(year, "VALUE") or Game.BaseYear
		local hour_val = iup.GetInt(hour, "VALUE") or 0
		local minute_val = iup.GetInt(minute, "VALUE") or 0
		local tick_val = iup.GetInt(tick, "VALUE") or 0

		update_timestamp_display(year_val, month_val, date_val, hour_val, minute_val, tick_val, timestamp)
		update_moon_phase(date_val, moonphase)
		update_day_of_week(date_val, dayoftheweek)
		local timestamp_val = iup.GetInt(timestamp, "VALUE") or 0
		update_score(timestamp_val, score)
		update_terra_image(timestamp_val)

		return iup.DEFAULT
	end

	-- Add change handlers to all inputs
	iup.SetCallback(date_select, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(month_select, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(year, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(hour, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(minute, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(tick, "VALUECHANGED_CB", on_input_change)
	iup.SetCallback(timestamp, "VALUECHANGED_CB", function()
		local timestamp_val = iup.GetInt(timestamp, "VALUE") or 0
		update_inputs_from_timestamp(timestamp_val, date_select, month_select, year, hour, minute, tick, moonphase,
			dayoftheweek, score)
		return iup.DEFAULT
	end)

	-- Set button callbacks
	iup.SetCallback(game_start_button, "ACTION", function()
		iup.SetAttribute(date_select, "VALUE", 1)
		iup.SetAttribute(month_select, "VALUE", 1) -- January
		iup.SetAttribute(year, "VALUE", Game.BaseYear)
		iup.SetAttribute(hour, "VALUE", 9)
		iup.SetAttribute(minute, "VALUE", 0)
		iup.SetAttribute(tick, "VALUE", 0)
		on_input_change()
		return iup.DEFAULT
	end)

	iup.SetCallback(spring_equinox_button, "ACTION", function()
		iup.SetAttribute(date_select, "VALUE", 20)
		iup.SetAttribute(month_select, "VALUE", 3)
		on_input_change()
		return iup.DEFAULT
	end)

	iup.SetCallback(summer_solstice_button, "ACTION", function()
		iup.SetAttribute(date_select, "VALUE", 21)
		iup.SetAttribute(month_select, "VALUE", 6)
		on_input_change()
		return iup.DEFAULT
	end)

	iup.SetCallback(autumnal_equinox_button, "ACTION", function()
		iup.SetAttribute(date_select, "VALUE", 23)
		iup.SetAttribute(month_select, "VALUE", 9)
		on_input_change()
		return iup.DEFAULT
	end)

	iup.SetCallback(winter_solstice_button, "ACTION", function()
		iup.SetAttribute(date_select, "VALUE", 21)
		iup.SetAttribute(month_select, "VALUE", 12)
		on_input_change()
		return iup.DEFAULT
	end)

	iup.SetCallback(apply_button, "ACTION", function()
		local timestamp_val = iup.GetInt(timestamp, "VALUE") or 0
		Game.Time = timestamp_val
		return iup.DEFAULT
	end)

	iup.SetCallback(reset_button, "ACTION", function()
		update_from_game_time()
		return iup.DEFAULT
	end)

	-- Initialize with current game time
	update_from_game_time()

	local function weather_reset()
		if snow_checkbox then
			iup.SetAttribute(snow_checkbox, "VALUE", Game.Weather.Snow and "ON" or "OFF")
		end
		if rain_checkbox then
			iup.SetAttribute(rain_checkbox, "VALUE", Game.Weather.Rain and "ON" or "OFF")
		end
		iup.SetAttribute(fog_checkbox, "VALUE", Game.Weather.Fog and "ON" or "OFF")
	end

	weather_reset()

	-- Set callbacks for weather buttons
	iup.SetCallback(weather_apply_button, "ACTION", function()
		-- Apply current weather settings
		if snow_checkbox then
			local snow_value = iup.GetAttribute(snow_checkbox, "VALUE") == "ON"
			evt.SetSnow(0, snow_value)
		end

		if rain_checkbox then
			local rain_value = iup.GetAttribute(rain_checkbox, "VALUE") == "ON"
			if (Game.Weather.Rain and rain_value == false) or (not Game.Weather.Rain and rain_value == true) then
				Game.Weather.Rain = rain_value
			end
		end

		local fog_value = iup.GetAttribute(fog_checkbox, "VALUE") == "ON"
		utils.set_fog(fog_value)
		return iup.DEFAULT
	end)

	iup.SetCallback(weather_reset_button, "ACTION", function()
		weather_reset()
		return iup.DEFAULT
	end)
end

function M.create()
	dayoftheweek = ui.input(1, {
		READONLY = "YES",
		BGCOLOR = ui.non_editable_input_bg_color,
		SIZE = "90x"
	})
	date_select = ui.select({}, nil, {
		EXPAND = "NO"
	})
	month_select = ui.select({ i18n._("january"), i18n._("february"), i18n._("march"), i18n._("april"), i18n._("may"),
		i18n._("june"), i18n._("july"), i18n._("august"), i18n._("september"), i18n._("october"),
		i18n._("november"), i18n._("december") }, nil, {
		EXPAND = "NO"
	})
	year = ui.uint_input(Game.BaseYear, {
		SPINMIN = Game.BaseYear
	})
	hour = ui.uint_input(0, {
		SPINMAX = 23
	})
	minute = ui.uint_input(0, {
		SPINMAX = 59
	})
	tick = ui.uint_input(0, {
		SPINMAX = 255
	})
	timestamp = ui.uint_input(0, {
		SIZE = "120x"
	})
	moonphase = ui.input(0, {
		READONLY = "YES",
		SIZE = "120x",
		BGCOLOR = ui.non_editable_input_bg_color
	})
	score = ui.input(0, {
		READONLY = "YES",
		SIZE = "120x",
		BGCOLOR = ui.non_editable_input_bg_color
	})

	game_start_button = ui.button(i18n._("game_start"), nil)
	spring_equinox_button = ui.button(i18n._("spring_equinox"), nil)
	summer_solstice_button = ui.button(i18n._("summer_solstice"), nil)
	autumnal_equinox_button = ui.button(i18n._("autumnal_equinox"), nil)
	winter_solstice_button = ui.button(i18n._("winter_solstice"), nil)

	apply_button = ui.button(i18n._("apply"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "60x"
	})
	reset_button = ui.button(i18n._("reset"), nil, {
		MINSIZE = "60x"
	})

	local time_format
	if i18n.get_lang_props().ymd then
		time_format = { year, ui.label(i18n._("year")), month_select, ui.label(i18n._("month")), date_select,
			ui.label(i18n._("date")), dayoftheweek }
	else
		time_format = { dayoftheweek, ui.label(i18n._("date")), date_select, ui.label(i18n._("month")), month_select,
			ui.label(i18n._("year")), year }
	end

	-- Add weather frame
	snow_checkbox = nil
	if Game.Version ~= 8 or Merge ~= nil then
		snow_checkbox = ui.checkbox(i18n._("snow"), nil)
	end
	rain_checkbox = nil
	if Game.Version == 8 then
		rain_checkbox = ui.checkbox(i18n._("rain"), nil)
	end
	fog_checkbox = ui.checkbox(i18n._("fog"), nil)

	weather_apply_button = ui.button(i18n._("apply"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "60x"
	})
	weather_reset_button = ui.button(i18n._("reset"), nil, {
		MINSIZE = "60x"
	})

	-- Create array of weather controls based on game version
	local weather_controls = {}
	if snow_checkbox then
		table.insert(weather_controls, snow_checkbox)
	end
	if rain_checkbox then
		table.insert(weather_controls, rain_checkbox)
	end
	table.insert(weather_controls, fog_checkbox)
	table.insert(weather_controls, weather_apply_button)
	table.insert(weather_controls, weather_reset_button)

	local weather_frame = ui.frame(i18n._("weather"), ui.button_hbox(weather_controls))

	terra_image_label_obj = ImageLabel:new({
		width = mmimage.terra_sizes.width,
		height = mmimage.terra_sizes.height,
		use_handle = true
	})

	local date_time_frame = ui.frame(i18n._("date_time"),
		ui.centered_vbox({ terra_image_label_obj.label, ui.hbox(), ui.hbox(time_format),
			ui.hbox({ ui.label(i18n._("time")), hour, ui.label(":"), minute, ui.label(":"), tick }),
			ui.label(i18n._("time_format_hint", const.Minute)),
			ui.hbox(
				{ ui.label(i18n._("timestamp_ticks")), timestamp, ui.label(i18n._("moon_phase")), moonphase,
					ui.label(i18n._("score")), score }),
			ui.button_hbox(
				{ game_start_button, spring_equinox_button, summer_solstice_button, autumnal_equinox_button,
					winter_solstice_button }), ui.button_hbox({ apply_button, reset_button }) }))

	return ui.vbox({ date_time_frame, weather_frame }, {
		TABTITLE = i18n._("time") .. i18n._("nn") .. i18n._("weather"),
		ALIGNMENT = "ACENTER"
	})
end

return M
