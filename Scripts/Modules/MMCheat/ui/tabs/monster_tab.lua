local ui = require("MMCheat/ui/components/ui_components")
local iup = require("iup")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")
local mmsprite = require("MMCheat/util/image/mmsprite")

local monster_image_width = 260
local monster_image_height = 300

local M = {}

local summon_monster_select
local looted_corpse_disappear_chance_input
local monster_image_label_obj

local function load_selected_monster_image()
	local monster_id = iup.GetInt(summon_monster_select, "VALUE")
	local ok, preview = pcall(mmsprite.get_monster_preview, monster_id, monster_image_width, monster_image_height)
	if ok and preview then
		monster_image_label_obj:load_pixels(preview.width, preview.height, preview.pixels)
		monster_image_label_obj:set_filename(preview.filename)
	else
		monster_image_label_obj:load_pixels(monster_image_width, monster_image_height)
	end
end

function M.cleanup()
	summon_monster_select = nil
	looted_corpse_disappear_chance_input = nil
	monster_image_label_obj = nil
end

function M.firstload()
	local monster_options = {}

	-- Initialize monster options
	for i = 1, Game.MonstersTxt.Count - 1 do
		table.insert(monster_options, enc.decode(Game.MonstersTxt[i].Name))
	end

	utils.load_select_options(summon_monster_select, monster_options, false, 1)
	load_selected_monster_image()

	-- Load looted corpse disappear chance value
	iup.SetAttribute(looted_corpse_disappear_chance_input, "VALUE", utils.GetLootedCorpseDisapProb())
end

function M.create()
	summon_monster_select = ui.select {}
	monster_image_label_obj = ImageLabel:new({
		width = monster_image_width,
		height = monster_image_height
	})
	looted_corpse_disappear_chance_input = ui.uint_input(0, {
		SIZE = "40x",
		SPINMAX = 100
	})

	local monster_ok_button = ui.button(i18n._("ok"), nil, {
		FGCOLOR = ui.apply_exit_button_color,
		MINSIZE = "60x"
	})
	local looted_corpse_ok_button = ui.button(i18n._("ok"), nil, {
		FGCOLOR = ui.apply_button_color,
		MINSIZE = "60x"
	})

	iup.SetCallback(monster_ok_button, "ACTION", function()
		local selected_index = iup.GetInt(summon_monster_select, "VALUE")
		if selected_index and selected_index ~= 0 then
			local x, y, z = utils.get_new_coord(Party.X, Party.Y, Party.Z, Party.Direction, 200)
			SummonMonster(selected_index, x, y, z)
			return iup.CLOSE
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(summon_monster_select, "VALUECHANGED_CB", function()
		load_selected_monster_image()
		return iup.DEFAULT
	end)

	iup.SetCallback(looted_corpse_disappear_chance_input, "VALUECHANGED_CB", function()
		local value = iup.GetInt(looted_corpse_disappear_chance_input, "VALUE")
		if value < 0 then
			iup.SetAttribute(looted_corpse_disappear_chance_input, "VALUE", 0)
		elseif value > 100 then
			iup.SetAttribute(looted_corpse_disappear_chance_input, "VALUE", 100)
		end
		return iup.DEFAULT
	end)

	iup.SetCallback(looted_corpse_ok_button, "ACTION", function()
		local value = iup.GetInt(looted_corpse_disappear_chance_input, "VALUE") or 0
		utils.SetLootedCorpseDisapProb(value)
		return iup.DEFAULT
	end)

	return ui.vbox({ ui.frame(i18n._("summon"), { ui.vbox({
		ui.hbox({ summon_monster_select, monster_ok_button }), monster_image_label_obj.label
	}, { ALIGNMENT = "ACENTER" }) }),
		ui.frame(i18n._("looting"), { ui.labelled_fields(i18n._("looted_corpse_disappear_chance"),
			{ looted_corpse_disappear_chance_input, ui.label("%"), looted_corpse_ok_button }, 120) }) }, {
		TABTITLE = i18n._("monster"),
		ALIGNMENT = "ACENTER"
	})
end

return M
