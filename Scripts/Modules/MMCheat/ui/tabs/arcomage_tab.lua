local ui = require("MMCheat/ui/components/ui_components")
local iup = require("iup")
local i18n = require("MMCheat/i18n/i18n")

local M = {}

-- Input fields for player
local player_brick_prod, player_bricks
local player_gem_prod, player_gems
local player_recruit_prod, player_recruits
local player_tower, player_wall

-- Input fields for enemy
local enemy_brick_prod, enemy_bricks
local enemy_gem_prod, enemy_gems
local enemy_recruit_prod, enemy_recruits
local enemy_tower, enemy_wall

-- Input fields for win condition
local tower_to_win, res_to_win

function M.cleanup()
	player_brick_prod, player_bricks = nil
	player_gem_prod, player_gems = nil
	player_recruit_prod, player_recruits = nil
	player_tower, player_wall = nil

	enemy_brick_prod, enemy_bricks = nil
	enemy_gem_prod, enemy_gems = nil
	enemy_recruit_prod, enemy_recruits = nil
	enemy_tower, enemy_wall = nil

	tower_to_win, res_to_win = nil
end

-- Initialize values from game state
local function reset()
	local player = Game.Arcomage.Players[0]
	local enemy = Game.Arcomage.Players[1]

	if player then
		iup.SetAttribute(player_brick_prod, "VALUE", player.Income[0])
		iup.SetAttribute(player_bricks, "VALUE", player.Res[0])
		iup.SetAttribute(player_gem_prod, "VALUE", player.Income[1])
		iup.SetAttribute(player_gems, "VALUE", player.Res[1])
		iup.SetAttribute(player_recruit_prod, "VALUE", player.Income[2])
		iup.SetAttribute(player_recruits, "VALUE", player.Res[2])
		iup.SetAttribute(player_tower, "VALUE", player.Tower)
		iup.SetAttribute(player_wall, "VALUE", player.Wall)
	end

	if enemy then
		iup.SetAttribute(enemy_brick_prod, "VALUE", enemy.Income[0])
		iup.SetAttribute(enemy_bricks, "VALUE", enemy.Res[0])
		iup.SetAttribute(enemy_gem_prod, "VALUE", enemy.Income[1])
		iup.SetAttribute(enemy_gems, "VALUE", enemy.Res[1])
		iup.SetAttribute(enemy_recruit_prod, "VALUE", enemy.Income[2])
		iup.SetAttribute(enemy_recruits, "VALUE", enemy.Res[2])
		iup.SetAttribute(enemy_tower, "VALUE", enemy.Tower)
		iup.SetAttribute(enemy_wall, "VALUE", enemy.Wall)
	end

	-- Set win condition values
	iup.SetAttribute(tower_to_win, "VALUE", Game.Arcomage.TowerToWin)
	iup.SetAttribute(res_to_win, "VALUE", Game.Arcomage.ResToWin)
end

function M.firstload()
	reset()
end

local long_label_min_width = 90
local short_label_min_width = 50
local input_size = "60x"
local button_size = "60x"

function M.create()
	-- Create player input fields
	player_brick_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	player_bricks = ui.uint_input(0, {
		SIZE = input_size
	})
	player_gem_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	player_gems = ui.uint_input(0, {
		SIZE = input_size
	})
	player_recruit_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	player_recruits = ui.uint_input(0, {
		SIZE = input_size
	})
	player_tower = ui.uint_input(0, {
		SIZE = input_size
	})
	player_wall = ui.uint_input(0, {
		SIZE = input_size
	})

	-- Create enemy input fields
	enemy_brick_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_bricks = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_gem_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_gems = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_recruit_prod = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_recruits = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_tower = ui.uint_input(0, {
		SIZE = input_size
	})
	enemy_wall = ui.uint_input(0, {
		SIZE = input_size
	})

	-- Create player frame
	local player_frame = ui.frame(i18n._("player"), ui.hbox({ -- Left column
		ui.vbox({

			ui.frame(i18n._("brick"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { player_brick_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { player_bricks }, long_label_min_width, false) })),
			ui.frame(i18n._("gem"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { player_gem_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { player_gems }, long_label_min_width, false) })),
			ui.frame(i18n._("recruit"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { player_recruit_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { player_recruits }, long_label_min_width, false) }))

		}), -- Right column
		ui.vbox({ ui.labelled_fields(i18n._("tower"), { player_tower }, short_label_min_width, false), ui
			.labelled_fields(i18n._("wall"), { player_wall }, short_label_min_width) }) }))

	-- Create enemy frame
	local enemy_frame = ui.frame(i18n._("enemy"), ui.hbox({                    -- Left column
		ui.vbox({ ui.labelled_fields(i18n._("tower"), { enemy_tower }, short_label_min_width, false), ui
			.labelled_fields(i18n._("wall"), { enemy_wall }, short_label_min_width) }), -- Right column
		ui.vbox({

			ui.frame(i18n._("brick"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { enemy_brick_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { enemy_bricks }, long_label_min_width, false) })),
			ui.frame(i18n._("gem"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { enemy_gem_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { enemy_gems }, long_label_min_width, false) })),
			ui.frame(i18n._("recruit"),
				ui.vbox({ ui.labelled_fields(i18n._("production"), { enemy_recruit_prod }, long_label_min_width),
					ui.labelled_fields(i18n._("resource"), { enemy_recruits }, long_label_min_width, false) }))

		}) }))

	-- Create win condition inputs
	tower_to_win = ui.input(0, {
		READONLY = "YES",
		SIZE = input_size,
		BGCOLOR = ui.non_editable_input_bg_color
	})
	res_to_win = ui.input(0, {
		READONLY = "YES",
		SIZE = input_size,
		BGCOLOR = ui.non_editable_input_bg_color
	})

	-- Create win condition frame
	local win_condition_frame = ui.frame("",
		ui.hbox({ ui.labelled_fields(i18n._("tower_to_win"), { tower_to_win }, long_label_min_width, false), ui
			.labelled_fields(i18n._("resource_to_win"), { res_to_win }, long_label_min_width, false) }))

	-- Create buttons
	local ok_button = ui.button(i18n._("ok"), nil, {
		MINSIZE = button_size,
		FGCOLOR = ui.apply_exit_button_color
	})
	local reset_button = ui.button(i18n._("reset"), nil, {
		MINSIZE = button_size
	})

	iup.SetCallback(ok_button, "ACTION", function()
		local player = Game.Arcomage.Players[0]
		local enemy = Game.Arcomage.Players[1]

		if player then
			player.Income[0] = iup.GetInt(player_brick_prod, "VALUE") or 0
			player.Res[0] = iup.GetInt(player_bricks, "VALUE") or 0
			player.Income[1] = iup.GetInt(player_gem_prod, "VALUE") or 0
			player.Res[1] = iup.GetInt(player_gems, "VALUE") or 0
			player.Income[2] = iup.GetInt(player_recruit_prod, "VALUE") or 0
			player.Res[2] = iup.GetInt(player_recruits, "VALUE") or 0
			player.Tower = iup.GetInt(player_tower, "VALUE") or 0
			player.Wall = iup.GetInt(player_wall, "VALUE") or 0
		end

		if enemy then
			enemy.Income[0] = iup.GetInt(enemy_brick_prod, "VALUE") or 0
			enemy.Res[0] = iup.GetInt(enemy_bricks, "VALUE") or 0
			enemy.Income[1] = iup.GetInt(enemy_gem_prod, "VALUE") or 0
			enemy.Res[1] = iup.GetInt(enemy_gems, "VALUE") or 0
			enemy.Income[2] = iup.GetInt(enemy_recruit_prod, "VALUE") or 0
			enemy.Res[2] = iup.GetInt(enemy_recruits, "VALUE") or 0
			enemy.Tower = iup.GetInt(enemy_tower, "VALUE") or 0
			enemy.Wall = iup.GetInt(enemy_wall, "VALUE") or 0
		end

		return iup.CLOSE
	end)

	iup.SetCallback(reset_button, "ACTION", function()
		reset()
		return iup.DEFAULT
	end)

	-- Create main layout
	return ui.centered_vbox(
		{ ui.hbox({ player_frame, enemy_frame }), ui.button_hbox({ ok_button, reset_button }), win_condition_frame }, {
			TABTITLE = i18n._("arcomage")
		})
end

return M
