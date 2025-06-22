local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")
local utils = require("MMCheat/util/utils")
local enc = require("MMCheat/i18n/encoding")
local states = require("MMCheat/util/states")

local M = {}

local inputs

function M.cleanup()
	inputs = nil
end

local function update_fields(char_index)
	local char = Party.PlayersArray[char_index]
	if char then
		-- Update skills
		if inputs then
			for skill_name, skill_value in pairs(const.Skills) do
				local skill_level, mastery = SplitSkill(char.Skills[skill_value])
				if inputs[skill_name] then
					-- Update skill level
					iup.SetAttribute(inputs[skill_name].level, "VALUE", skill_level or 0)

					-- Update mastery dropdown
					local mastery_index = 1 -- Default to "Not learned"
					if mastery then
						mastery_index = mastery + 1 -- Map 1-4 to 2-5
					end
					iup.SetAttribute(inputs[skill_name].mastery, "VALUE", mastery_index)
				end
			end
		end
	end
end

-- function M.parent_firstload()
-- end

function M.parent_reload()
	if states.get_charsubtab_loaded(M) then
		update_fields(states.get_char_index())
	end
end

function M.parent_select_change()
	if states.get_charsubtab_loaded(M) then
		update_fields(states.get_char_index())
	end
end

function M.parent_apply()
	if states.get_charsubtab_loaded(M) then
		local char = Party.PlayersArray[states.get_char_index()]
		if char then
			-- Update skills
			if inputs then
				for skill_key, skill_value in pairs(const.Skills) do
					if inputs[skill_key] then
						local level = iup.GetInt(inputs[skill_key].level, "VALUE") or 0
						local mastery_value = iup.GetInt(inputs[skill_key].mastery, "VALUE") or 1

						-- Convert mastery dropdown index (1-5) to mastery constant (0-4)
						local mastery = mastery_value - 1

						-- Only set mastery if level > 0
						if level > 0 then
							char.Skills[skill_value] = JoinSkill(level, mastery)
						else
							char.Skills[skill_value] = 0
						end
					end
				end
			end
		end
	end
end

-- function M.reload()
-- end

function M.firstload()
	update_fields(states.get_char_index())
end

function M.create()
	local function create_skill_row(label, value, level)
		return ui.labelled_fields(label, { value, level }, 100)
	end

	local skills = {}
	local sorted_skill_items = {}
	for key, value in pairs(const.Skills) do
		table.insert(sorted_skill_items, {
			key = key,
			value = value
		})
	end
	table.sort(sorted_skill_items, function(a, b)
		return a.value < b.value
	end)

	-- Create three vboxes for different skill groups
	local first_group = ui.vbox {}
	local second_group = ui.vbox {}
	local third_group = ui.vbox {}

	-- Store input references
	inputs = {}

	-- Split skills into three groups
	for i, item in ipairs(sorted_skill_items) do
		local skill_name = enc.decode(Game.SkillNames[item.value])
		local skill_level = ui.uint_input(0, {
			SPINMAX = 255,
			SIZE = "40x"
		})
		local mastery = ui.select(utils.get_mastery_array())
		-- Set default value to "Not learned"
		iup.SetAttribute(mastery, "VALUE", "1")

		-- Add callbacks for interdependencies
		iup.SetCallback(mastery, "ACTION", function()
			local mastery_value = iup.GetInt(mastery, "VALUE")
			local level_value = iup.GetInt(skill_level, "VALUE")

			if mastery_value > 1 and level_value == 0 then
				-- If selecting any mastery other than "Not learned" and level is 0, set level to 1
				iup.SetAttribute(skill_level, "VALUE", "1")
			elseif mastery_value == 1 and level_value > 0 then
				-- If selecting "Not learned" and level is not 0, set level to 0
				iup.SetAttribute(skill_level, "VALUE", "0")
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(skill_level, "VALUECHANGED_CB", function()
			local level_value = iup.GetInt(skill_level, "VALUE")
			local mastery_value = iup.GetInt(mastery, "VALUE")

			if level_value == 0 and mastery_value > 1 then
				-- If level is set to 0 and mastery is not "Not learned", set mastery to "Not learned"
				iup.SetAttribute(mastery, "VALUE", "1")
			elseif level_value > 0 and mastery_value == 1 then
				-- If level is set to non-0 and mastery is "Not learned", set mastery to "Novice"
				iup.SetAttribute(mastery, "VALUE", "2")
			end
			return iup.DEFAULT
		end)

		local row = create_skill_row(skill_name .. "", skill_level, mastery)

		-- Store input references using the skill key
		inputs[item.key] = {
			level = skill_level,
			mastery = mastery
		}

		if i <= 12 then
			iup.Append(first_group, row)
		elseif i <= utils.mm67or8(21, 24) then
			iup.Append(second_group, row)
		else
			iup.Append(third_group, row)
		end
	end

	-- Create frames for each group
	local first_frame = ui.frame(i18n._("weapons_armors"), first_group)
	local second_frame = ui.frame(i18n._("magic"), second_group)
	local third_frame = ui.frame(i18n._("misc"), third_group)

	return ui.hbox({ first_frame, second_frame, third_frame }, {
		TABTITLE = i18n._("skills"),
		ALIGNMENT = "ATOP"
	})
end

return M
