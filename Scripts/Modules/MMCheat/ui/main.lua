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
	-- IupOpen/IupClose must bracket every MMCheat session: IupOpen enters a
	-- COM apartment (CoInitializeEx) and IupClose leaves it again. Leaving IUP
	-- open after the dialog closes leaves the game's main thread in an
	-- apartment it never asked for, which breaks the game (the game's own
	-- DirectDraw/Direct3D is COM based).
	-- IupOpen returns IUP_OPENED when IUP is already open, only IUP_ERROR is a
	-- failure.
	if iup.Open(nil, nil) == iup.ERROR then
		Game.ShowStatusText("MMCheat: IUP initialization failed")
		return
	end
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
		TITLE = about.short_name .. i18n._("colon") .. i18n._("title") .. " v" .. about.version
	})

	-- In the game process, IUP 3.32 measures the window decoration height
	-- wrong (~400px instead of ~40px) at every layout computation that happens
	-- before the dialog window has actually been shown once, which made the
	-- dialog open far too tall. Workaround: show it fully transparent first
	-- (so nothing wrong is visible), then - with the window metrics now
	-- settled - reset the size, recompute the layout, re-center, and reveal.
	iup.SetAttribute(dlg, "OPACITY", "0")
	iup.ShowXY(dlg, iup.CENTER, iup.CENTER)
	pcall(function()
		iup.SetAttribute(dlg, "SIZE", nil)
		iup.Refresh(dlg)
		iup.ShowXY(dlg, iup.CENTER, iup.CENTER)
	end)
	-- always reveal, even if the re-layout above failed for any reason
	iup.SetAttribute(dlg, "OPACITY", "255")

	-- dialog opens, pause game
	-- Game.DoPause()
	iup.MainLoop()

	-- dialog closes, resume game
	-- Game.DoResume()

	-- Execute all registered cleanup functions
	states.execute_cleanup()

	-- Teardown order matters: destroying widgets and closing IUP can still
	-- fire callbacks (unmap, killfocus...), so the callbacks may only be freed
	-- once no IUP object that could call them exists any more.
	iup.Destroy(dlg)
	iup.Close()
	iup.FreeCallbacks()
	collectgarbage("collect")

	return iup.CLOSE
end

return main
