local iup = require("iup")
local jit = require("jit")
local ui = require("MMCheat/ui/components/ui_components")
local langs = require("MMCheat/i18n/langs")
local i18n = require("MMCheat/i18n/i18n")
local about = require("MMCheat/about")
local ini = require("MMCheat/util/general/ini")
local enc = require("MMCheat/i18n/encoding")
local system = require("MMCheat/util/general/system")
local settings = require("MMCheat/util/settings")
local utils = require("MMCheat/util/utils")
local states = require("MMCheat/util/states")

local M = {}

local lang_select, game_encoding_select, auto_detect_button, language_ok_button
local stop_other_proc_checkbox, stop_now_button

function M.cleanup()
	lang_select, game_encoding_select, auto_detect_button, language_ok_button = nil
	stop_other_proc_checkbox, stop_now_button = nil
end

function M.firstload()
	local lang_display_names = {}
	local lang_codes = {}

	for _, lang in ipairs(langs) do
		local display_name = lang.loc .. i18n._("left_paren") .. lang.en .. i18n._("right_paren")
		lang_display_names[#lang_display_names + 1] = display_name
		lang_codes[#lang_codes + 1] = lang.code
	end

	utils.load_select_options(lang_select, lang_display_names)

	local current_lang = i18n.get_lang()
	for index, name in ipairs(lang_codes) do
		if name == current_lang then
			iup.SetAttribute(lang_select, "VALUE", index)
			break
		end
	end

	local game_encoding_display_names = {}
	local game_encodings = {}

	-- Create a temporary table to sort
	local temp = {}
	for code, name in pairs(enc.encodings) do
		-- Find all languages using this encoding
		local langs_using_encoding = {}
		for _, lang in ipairs(langs) do
			if lang.encoding == code then
				table.insert(langs_using_encoding, lang.loc)
			end
		end
		-- Create display name with languages in parentheses
		local display_name = name
		if #langs_using_encoding > 0 then
			display_name = name ..
				i18n._("left_paren") .. table.concat(langs_using_encoding, ", ") .. i18n._("right_paren")
		end
		table.insert(temp, {
			code = code,
			name = display_name
		})
	end

	-- Sort by display name in reverse order
	table.sort(temp, function(a, b)
		return a.name > b.name
	end)

	-- Build the final arrays in sorted order
	for _, item in ipairs(temp) do
		table.insert(game_encoding_display_names, item.name)
		table.insert(game_encodings, item.code)
	end

	utils.load_select_options(game_encoding_select, game_encoding_display_names)

	local current_game_encoding = i18n.get_game_encoding()
	for index, name in ipairs(game_encodings) do
		if name == current_game_encoding then
			iup.SetAttribute(game_encoding_select, "VALUE", index)
			break
		end
	end

	local function change_language_callback()
		local selected_index = iup.GetAttribute(lang_select, "VALUE")
		local lang_code = lang_codes[tonumber(selected_index)]
		local selected_enc_index = iup.GetAttribute(game_encoding_select, "VALUE")
		local enc_code = game_encodings[tonumber(selected_enc_index)]
		if (lang_code and lang_code ~= i18n.get_lang()) or (enc_code and enc_code ~= i18n.get_game_encoding()) then
			ini.write(settings.conf_path, {
				lang = {
					lang = lang_code,
					game_encoding = enc_code
				}
			}, 1)
		end
		return iup.CLOSE
	end

	local function auto_detect_encoding_callback()
		local detected_encoding = i18n.detect_game_encoding()
		for index, enc in ipairs(game_encodings) do
			if enc == detected_encoding then
				iup.SetAttribute(game_encoding_select, "VALUE", index)
				break
			end
		end
		return iup.DEFAULT
	end

	iup.SetCallback(auto_detect_button, "ACTION", auto_detect_encoding_callback)

	iup.SetCallback(language_ok_button, "ACTION", change_language_callback)

	-- Read initial value from conf.ini
	local should_kill_before_go_to = settings.get_setting("stop_other_proc_before_first_go_to") == "true"
	iup.SetAttribute(stop_other_proc_checkbox, "VALUE", should_kill_before_go_to and "ON" or "OFF")

	iup.SetCallback(stop_other_proc_checkbox, "ACTION", function()
		local value = iup.GetAttribute(stop_other_proc_checkbox, "VALUE") == "ON"
		settings.set_setting("stop_other_proc_before_first_go_to", value)
		return iup.DEFAULT
	end)

	iup.SetCallback(stop_now_button, "ACTION", function()
		system.stop_other_processes("mm" .. Game.Version .. ".exe")
		return iup.DEFAULT
	end)
end

function M.create()
	lang_select = ui.select {}

	local lang_labelled_fields = ui.labelled_fields(i18n._("mmcheat_language"), { lang_select })

	game_encoding_select = ui.select {}

	local game_encoding_labelled_fields = ui.labelled_fields(i18n._("game_encoding"), { game_encoding_select })

	auto_detect_button = ui.button(i18n._("auto_detect_encoding"))

	language_ok_button = ui.button(i18n._("ok_restart"), nil, {
		FGCOLOR = ui.apply_exit_button_color
	})

	local language_frame = ui.frame(i18n._("language"),
		ui.vbox({ ui.hbox({ lang_labelled_fields, game_encoding_labelled_fields }),
			ui.button_hbox({ language_ok_button, auto_detect_button }) }, {
			ALIGNMENT = "ACENTER"
		}))

	-- Create about information frame
	local about_frame = ui.frame(i18n._("about"), ui.vbox({ ui.centered_vbox({ states.logo.label }, nil, {
		SIZE = "110x"
	}), ui.hbox({ ui.label(about.short_name ..
		" " .. about.version .. i18n._("left_paren") .. about.version_date .. i18n._("right_paren")) }),
		ui.hbox({ iup.link(about.home_url, i18n._("homepage")) }),
		ui.hbox(
			{ ui.label(i18n._("author")), iup.link(about.author_url, about.author) }),
		ui.hbox(
			{ ui.label(i18n._("license")), iup.link(about.license_url, about.license) }),
		ui.hbox(
			{ iup.link(about.mmextension_url, "MMExtension"), ui.label(about.mmextension_version) }),
		ui.hbox(
			{ iup.link(about.grayfacepatch_url, "Grayface Patch"), ui.label(about.grayfacepatch_version) }),
		_VERSION and ui.hbox({ ui.label(_VERSION) }),

		jit and jit.version and ui.hbox({ ui.label(jit.version) }),
		ui.hbox({ ui.label("IUP " .. iup._VERSION) }) }))

	-- Create tips frame
	local tips_vbox = ui.vbox({})

	-- Add each line to the vbox
	iup.Append(tips_vbox, ui.label(i18n._("open_shortcut") .. "  ")) -- fix label bug when it contains emoji
	iup.Append(tips_vbox, ui.label(nil))

	-- Red button line
	local red_button_line = ui.hbox({ ui.label("- "), ui.label(i18n._("red_button"), {
		FGCOLOR = ui.apply_exit_button_color
	}), ui.label(i18n._("colon") .. i18n._("red_button_desc")) }, {
		MARGIN = "0X0",
		GAP = "0"
	})
	iup.Append(tips_vbox, red_button_line)

	-- Green button line
	local green_button_line = ui.hbox({ ui.label("- "), ui.label(i18n._("green_button"), {
		FGCOLOR = ui.apply_button_color
	}), ui.label(i18n._("colon") .. i18n._("green_button_desc")) }, {
		MARGIN = "0X0",
		GAP = "0"
	})
	iup.Append(tips_vbox, green_button_line)

	-- Black button line
	local black_button_line = ui.hbox(
		{ ui.label("- "), ui.label(i18n._("black_button")), ui.label(i18n._("colon") .. i18n._("black_button_desc")) }, {
			MARGIN = "0X0",
			GAP = "0"
		})
	iup.Append(tips_vbox, black_button_line)

	-- Orange label line
	local orange_label_line = ui.hbox({ ui.label("- "), ui.label(i18n._("orange_label"), {
		FGCOLOR = ui.onetime_change_label_color
	}), ui.label(i18n._("colon") .. i18n._("orange_label_desc")) }, {
		MARGIN = "0X0",
		GAP = "0"
	})
	iup.Append(tips_vbox, orange_label_line)
	iup.Append(tips_vbox, ui.label(nil))


	-- Image controls section
	iup.Append(tips_vbox, ui.label("- " .. i18n._("click_on_map")))
	iup.Append(tips_vbox, ui.label("- " .. i18n._("click_on_circle_controls")))
	iup.Append(tips_vbox, ui.label("- " .. i18n._("right_click_on_image")))
	iup.Append(tips_vbox, ui.label(nil))

	-- Keyboard shortcuts section
	iup.Append(tips_vbox, ui.label(i18n._("dropdown_shortcuts")))
	iup.Append(tips_vbox, ui.label("- " .. string.format(i18n._("find_in_list_shortcut"), i18n._("find_in_list"))))
	iup.Append(tips_vbox, ui.label("- " .. i18n._("copy_shortcut")))
	iup.Append(tips_vbox, ui.label(nil))

	-- Read more docs
	iup.Append(tips_vbox, ui.hbox({ ui.label(i18n._("read_more_docs")), iup.link(about.home_url, i18n._("homepage")) }))

	local tips_frame = ui.frame(i18n._("tips"), tips_vbox)

	-- Create process management frame
	stop_other_proc_checkbox = ui.checkbox(i18n._("stop_before_go_to"), nil, {
		FGCOLOR = ui.apply_button_color
	})

	stop_now_button = ui.button(i18n._("stop_now"), nil, {
		FGCOLOR = ui.apply_button_color
	})

	local stop_process_frame = ui.frame(i18n._("stop_other_processes", Game.Version),
		ui.vbox({ stop_now_button, stop_other_proc_checkbox }, {
			ALIGNMENT = "ACENTER"
		}))

	local right_vbox = ui.vbox({ tips_frame, stop_process_frame }, {
		ALIGNMENT = "ACENTER"
	})

	return ui.vbox({ language_frame, ui.hbox({ about_frame, right_vbox }, {
		ALIGNMENT = "ATOP",
		GAP = "52"
	}) }, {
		TABTITLE = i18n._("language") .. i18n._("nn") .. i18n._("about") .. ' 💬',
		ALIGNMENT = "ACENTER"
	})
end

return M
