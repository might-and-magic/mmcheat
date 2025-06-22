-- MMCheat: Might and Magic 678 Merge and GrayFace Might and Magic 6/7/8 Cheat Suite & Helper Tool
-- CTRL + Backspace in the game to open MMCheat
-- https://github.com/might-and-magic/mmcheat
-- By Tom Chen. MIT License
local iup = require("iup")
local i18n = require("MMCheat/i18n/i18n")
local settings = require("MMCheat/util/settings")
local about = require("MMCheat/about")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")

local states = require("MMCheat/util/states")
local ui = require("MMCheat/ui/components/ui_components")
local lazytabs = require("MMCheat/ui/components/lazytabs")

local map_tab = require("MMCheat/ui/tabs/map_tab")
local god_mode_tab = require("MMCheat/ui/tabs/god_mode_tab")
local characters_tab = require("MMCheat/ui/tabs/characters_tab")
local npc_tab = require("MMCheat/ui/tabs/npc_tab")
local monster_tab = require("MMCheat/ui/tabs/monster_tab")
local item_tab = require("MMCheat/ui/tabs/item_tab")
local active_spells_tab = require("MMCheat/ui/tabs/active_spells_tab")
local party_tab = require("MMCheat/ui/tabs/party_tab")
local time_tab = require("MMCheat/ui/tabs/time_tab")
local arcomage_tab
if Game.Version ~= 6 then
	arcomage_tab = require("MMCheat/ui/tabs/arcomage_tab")
end
local about_tab = require("MMCheat/ui/tabs/about_tab")
-- local test_tab = require("MMCheat/ui/tabs/test_tab")

local function main()
	iup.Open(nil, nil)
	iup.SetGlobal("UTF8MODE", "YES")

	states.cleanup()
	i18n.init()
	settings.init()

	states.logo = ImageLabel:new({
		width = 32,
		height = 32,
		use_handle = true
	})
	states.logo:load_bmp_file("Scripts/Modules/MMCheat/img/logo32.bmp")
	-- states.logo.label is used only in about_tab.lua

	local tab_table = { map_tab, god_mode_tab, characters_tab, party_tab, npc_tab, monster_tab, item_tab,
		active_spells_tab, time_tab }
	if Game.Version ~= 6 then
		table.insert(tab_table, arcomage_tab)
	end
	table.insert(tab_table, about_tab)
	-- table.insert(tab_table, test_tab)

	local tabs = {}
	for _, tab in ipairs(tab_table) do
		if tab then
			table.insert(tabs, tab)
		end
	end
	local lazy_tabs = lazytabs(tabs)

	local dlg = ui.dialog(lazy_tabs, {
		TITLE = i18n._("title") .. " v" .. about.version
	})

	iup.ShowXY(dlg, iup.CENTER, iup.CENTER)

	-- dialog opens, pause game
	-- Game.DoPause()
	iup.MainLoop()

	-- dialog closes, resume game
	-- Game.DoResume()

	-- Execute all registered cleanup functions
	states.execute_cleanup()
	collectgarbage("collect")

	-- free callbacks
	iup.FreeCallbacks()

	iup.Destroy(dlg)
	iup.Close()
	return iup.CLOSE
end

return main
