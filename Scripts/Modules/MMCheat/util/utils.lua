local iup = require("iup")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local ini = require("MMCheat/util/general/ini")
local states = require("MMCheat/util/states")
local bit = require("bit")

local M = {}

function M.mm678(value_when_6, value_when_7, value_when_8)
	if Game.Version == 6 then
		return value_when_6
	elseif Game.Version == 7 then
		return value_when_7
	elseif Game.Version == 8 then
		return value_when_8 -- mm8 includes mmmerge
	end
	return nil
end

function M.mmotherormerge(value_when_other, value_when_mmmerge)
	if Merge == nil then
		return value_when_other
	else
		return value_when_mmmerge
	end
end

function M.mm678merge(value_when_6, value_when_7, value_when_8, value_when_mmmerge)
	if Game.Version == 6 then
		return value_when_6
	elseif Game.Version == 7 then
		return value_when_7
	elseif Game.Version == 8 then
		if Merge == nil then --- mm8, not merge
			return value_when_8
		else           --- merge
			return value_when_mmmerge
		end
	end
	return nil
end

function M.mm6or78(value_when_6, value_when_7_or_8)
	if Game.Version == 6 then
		return value_when_6
	elseif Game.Version == 7 or Game.Version == 8 then
		return value_when_7_or_8 -- mm8 includes mmmerge
	end
	return nil
end

function M.mm67or8(value_when_6_or_7, value_when_8)
	if Game.Version == 6 or Game.Version == 7 then
		return value_when_6_or_7
	elseif Game.Version == 8 then
		return value_when_8 -- mm8 includes mmmerge
	end
	return nil
end

-- `Merge ~= nil` to see if it's mmmerge

-- Select an item in a select control
-- @param select_control iup.control
-- @param index number
-- @param fallback number
-- @return number index of the finally and actually selected item index (0: "blank", 1: first item, n: nth item)
-- index: set to that index (0: select "blank", 1: select first item, n: select nth item), if it's out of range, do nothing
-- fallback (if index is out of range, then):
-- - `nil`: do nothing
-- - `1`: select the 1st item, if it's still out of range, select 0 ("blank")
-- - `-1`: select the last item, if it's still out of range, select 0 ("blank") (useful for deleting item in select)
-- - anything else: select 0 ("blank")
function M.select_item_in_select(select_control, index, fallback)
	local count = iup.GetInt(select_control, "COUNT")
	if index ~= nil then
		if index >= 0 and index <= count then
			iup.SetAttribute(select_control, "VALUE", tostring(index))
			return index
		elseif fallback == 1 and count > 0 then
			iup.SetAttribute(select_control, "VALUE", "1")
			return 1
		elseif fallback == -1 and count > 0 then
			iup.SetAttribute(select_control, "VALUE", tostring(count))
			return count
		end
		iup.SetAttribute(select_control, "VALUE", "0")
		return 0
	end
end

-- load select options, if it's not first-time load, set should_empty_first to true
-- `selection` can be (only works for single selectable controls):
-- - nil: do nothing
-- - number: same as {number, nil}
-- - true: remember the previously selected index and restore it, same as {previous_index, nil}
-- - {number_or_true, fallback}: number_or_true is the same as above; fallback is described in `M.select_item_in_select`
-- @return number index of the finally and actually selected item index (0: "blank", 1: first item, n: nth item) if selection is not nil
function M.load_select_options(select_control, options, should_empty_first, selection)
	local last_selected = iup.GetInt(select_control, "VALUE")
	if should_empty_first then
		iup.SetAttribute(select_control, "REMOVEITEM", "ALL")
	end
	local count = #options
	iup.SetAttribute(select_control, "COUNT", tostring(count))
	for i = 1, count do
		iup.SetAttribute(select_control, tostring(i), options[i])
	end

	if selection ~= nil then
		local selection_index
		local selection_fallback
		if type(selection) == "number" then
			selection_index = selection
			selection_fallback = nil
		elseif selection == true then
			selection_index = last_selected
			selection_fallback = nil
		elseif type(selection) == "table" then
			selection_index = selection[1]
			selection_fallback = selection[2]
			if type(selection_index) == "number" then
				selection_index = selection_index
			elseif selection_index == true then
				selection_index = last_selected
			end
		end
		if selection_index ~= nil then
			return M.select_item_in_select(select_control, selection_index, selection_fallback)
		end
	end
end

function M.get_7stats()
	return { "Might", "Intellect", "Personality", "Endurance", "Accuracy", "Speed", "Luck" }
end

function M.get_res()
	if Game.Version == 6 then
		return { "Fire", "Elec", "Cold", "Poison", "Magic" }
	else
		return { "Fire", "Air", "Water", "Earth", "Mind", "Body" }
	end
end

--- Convert time components to timestamp in ticks
-- @param year number
-- @param month number
-- @param date/days number
-- @param hour number
-- @param minute number
-- @param tick number
-- @param is_duration boolean Whether this is a duration (default: false)
-- @return number timestamp in ticks
function M.time_to_timestamp(year, month, date, hour, minute, tick, is_duration)
	is_duration = is_duration or false

	-- Calculate days
	local days = (year - (is_duration and 0 or Game.BaseYear)) * 336 -- 12 months * 28 days
	days = days + (month - (is_duration and 0 or 1)) * 28         -- Add months
	days = days + (date - (is_duration and 0 or 1))               -- Add days

	-- Convert to ticks
	local total_minutes = days * 24 * 60 + hour * 60 + minute
	return total_minutes * const.Minute + tick
end

--- Convert timestamp in ticks to time components
-- @param timestamp number timestamp in ticks
-- @param is_days boolean Whether this is a duration in days (default: false)
-- @return table Time components {years, months, days, hours, minutes, ticks}
function M.timestamp_to_time(timestamp, is_days)
	is_days = is_days or false

	local total_minutes = math.floor(timestamp / const.Minute)
	local remaining_ticks = timestamp % const.Minute

	local total_hours = math.floor(total_minutes / 60)
	local minutes = total_minutes % 60

	local total_days = math.floor(total_hours / 24)
	local hours = total_hours % 24

	if is_days then
		-- For durations, just return the raw days without month/year conversion
		return {
			days = total_days,
			hours = hours,
			minutes = minutes,
			ticks = remaining_ticks
		}
	else
		-- For absolute dates, use the month/year conversion
		local total_months = math.floor(total_days / 28)
		local days = total_days % 28 + 1
		local years = math.floor(total_months / 12) + Game.BaseYear
		local months = total_months % 12 + 1

		return {
			years = years,
			months = months,
			days = days,
			hours = hours,
			minutes = minutes,
			ticks = remaining_ticks
		}
	end
end

--- Calculate new coordinates for a point at a given distance and direction from a reference point
-- @param x number Reference point X coordinate
-- @param y number Reference point Y coordinate
-- @param z number Reference point Z coordinate
-- @param dir number Direction in game units (0-2047, where 0 is East)
-- @param distance number Distance from reference point
-- @return number,number,number,number New X,Y,Z coordinates and facing direction (opposite to reference point)
function M.get_new_coord(x, y, z, dir, distance)
	local two_pi = 2 * math.pi
	-- Convert direction to radians
	local angle = (dir / 2048) * two_pi

	-- Calculate new coordinates in front of player
	local new_x = x + distance * math.cos(angle)
	local new_y = y + distance * math.sin(angle)
	local new_z = z

	-- Monster faces the player (opposite direction)
	local new_dir = (dir + 1024) % 2048

	return new_x, new_y, new_z, new_dir
end

function M.merge_tables(t1, t2)
	for k, v in pairs(t2) do
		t1[k] = v
	end
	return t1
end

local text_globaltxt = {
	["Might"] = 144,
	["Intellect"] = 116,
	["Personality"] = 163,
	["Endurance"] = 75,
	["Accuracy"] = 1,
	["Speed"] = 211,
	["Luck"] = 136,
	["Fire"] = 87
}
if Game.Version == 6 then
	M.merge_tables(text_globaltxt, {
		["Electricity"] = 71,
		["Cold"] = 43,
		["Poison"] = 166,
		["Magic"] = 138,
		["Saintly"] = 510,
		["Angelic"] = 511,
		["Glorious"] = 512,
		["Honorable"] = 513,
		["Respectable"] = 514,
		["Average"] = 515,
		["Bad"] = 516,
		["Vile"] = 517,
		["Despicable"] = 518,
		["Monstrous"] = 519
	})
else
	M.merge_tables(text_globaltxt, {
		["Air"] = 6,
		["Water"] = 240,
		["Earth"] = 70,
		["Mind"] = 142,
		["Body"] = 29,
		["Hated"] = 379,
		["Unfriendly"] = 392,
		["Neutral"] = 399,
		["Friendly"] = 402,
		["Liked"] = 434
	})
end

function M.text_to_globaltxt(text)
	local globaltxt_index = text_globaltxt[text]
	if not globaltxt_index then
		return nil
	end
	return enc.decode(Game.GlobalTxt[globaltxt_index])
end

local const_globaltxt = {
	["Condition"] = {
		[0] = 52,
		[1] = 241,
		[2] = 14,
		[3] = 4,
		[4] = 69,
		[5] = 117,
		[6] = 166,
		[7] = 65,
		[8] = 166,
		[9] = 65,
		[10] = 166,
		[11] = 65,
		[12] = 162,
		[13] = 231,
		[14] = 58,
		[15] = 220,
		[16] = 76,
		[17] = M.mm6or78(nil, 601), -- 7 8 only
		[18] = 98
	},
	["PartyBuff"] = M.mm6or78({
		[0] = 458,
		[1] = 460,
		[2] = 459,
		[3] = 462,
		[4] = 461,
		[5] = 454,
		[6] = 456,
		[7] = 455,
		[8] = 457,
		[10] = 453,
		[11] = 452
	}, {
		[0] = 202,
		[1] = 204,
		[2] = 219,
		[3] = 215,
		[4] = 208,
		[5] = 454,
		[6] = 24,
		[7] = 455,
		[8] = 441,
		[9] = 440,
		[10] = 218,
		[11] = 217,
		[12] = 213,
		[13] = 462,
		[14] = 279,
		[15] = 442,
		[16] = 452,
		[17] = 194,
		[18] = 456,
		[19] = 453
	}),
	["PlayerBuff"] = M.mm6or78({
		[0] = 443,
		[1] = 440,
		[2] = 441,
		[3] = 279,
		[4] = 442,
		-- in-game naming vague and conflicted, keep these "Temp X"
		[5] = "Luck",
		[6] = "Intellect",
		[7] = "Personality",
		[8] = "Accuracy",
		[9] = "Speed",
		[10] = "Might",
		[11] = "Endurance"
	}, {
		[0] = 202,
		[1] = 443,
		[2] = 204,
		[3] = 208,
		[4] = 221,
		[5] = 24,
		[6] = 228,
		[7] = 441,
		[8] = 440,
		[9] = 213,
		[10] = 229,
		[11] = 233,
		[12] = 234,
		[13] = 279,
		[14] = 442,
		[15] = 235,
		[16] = 246,
		[17] = 247,
		[18] = 248,
		[19] = 674,
		[20] = 249,
		[21] = 258,
		[22] = 194,
		[23] = 657,
		[24] = M.mm67or8(nil, 700), -- mm8 only
		[25] = M.mm67or8(nil, 702), -- mm8 only
		[26] = M.mm67or8(nil, 701) -- mm8 only
	}),
	["NPCProfession"] = {
		[1] = 308,
		[2] = 309,
		[3] = 7,
		[4] = 306,
		[5] = 310,
		[6] = 311,
		[7] = 312,
		[8] = 313,
		[9] = 314,
		[10] = 105,
		[11] = 315,
		[12] = 316,
		[13] = 317,
		[14] = 115,
		[15] = 318,
		[16] = 319,
		[17] = 320,
		[18] = 321,
		[19] = 322,
		[20] = 323,
		[21] = 293,
		[22] = 324,
		[23] = M.mm6or78(325, 498),
		[24] = M.mm6or78(326, 525),
		[25] = 327,
		[26] = 328,
		[27] = 329,
		[28] = 330,
		[29] = 331,
		[30] = 332,
		[31] = 333,
		[32] = 334,
		[33] = 335,
		[34] = 336,
		[35] = 337,
		[36] = 338,
		[37] = 339,
		[38] = 340,
		[39] = 341,
		[40] = 342,
		[41] = 343,
		[42] = M.mm6or78(344, 596),
		[43] = 345,
		[44] = 346,
		[45] = 347,
		[46] = 348,
		[47] = 349,
		[48] = 350,
		[49] = M.mm6or78(351, 597),
		[50] = 352,
		[51] = 353
	}
}
local NPCProfessionTableMore = M.mm6or78({
	[52] = 305,
	[53] = 354,
	[54] = 355,
	[55] = 356,
	[56] = 357,
	[57] = 358,
	[58] = 359,
	[59] = 360,
	[60] = 361,
	[61] = 362,
	[62] = 363,
	[63] = 364,
	[64] = 365,
	[65] = 366,
	[66] = 367,
	[67] = 368,
	[68] = 369,
	[69] = 370,
	[70] = 371,
	[71] = 372,
	[72] = 42,
	[73] = 100,
	[74] = 373,
	[75] = 303,
	[76] = 374,
	[77] = 558
}, {
	[52] = 598,
	[53] = 344,
	[54] = 26,
	[55] = 599,
	[56] = 21,
	[57] = 600,
	[58] = 370
})
if NPCProfessionTableMore then
	for k, v in pairs(NPCProfessionTableMore) do
		const_globaltxt.NPCProfession[k] = v
	end
end
-- const.Condition (or const.PartyBuff or const.PlayerBuff)'s item value (a 0-based number) map to `Game.GlobalTxt[i]`'s index `i`, when const.Condition's item key (ShortName) corresponds with the Full Name stored in Game.GlobalTxt[i]
function M.const_to_globaltxt(const_type, const_index)
	if Merge ~= nil and const_type == "NPCProfession" then
		local prof_name = Game.NPCProfessions[const_index]
		if prof_name then
			return enc.decode(prof_name)
		end
		return nil
	end
	local globaltxt_index = const_globaltxt[const_type][const_index]
	if globaltxt_index == nil then
		return nil
	end
	if type(globaltxt_index) == "string" then
		return i18n._("temp_x", M.text_to_globaltxt(globaltxt_index))
	end
	return enc.decode(Game.GlobalTxt[globaltxt_index])
end

local class_promotion = M.mm678merge({
	-- mm6
	[0] = 2,
	[1] = 2,
	[3] = 5,
	[4] = 5,
	[6] = 8,
	[7] = 8,
	[9] = 11,
	[10] = 11,
	[12] = 14,
	[13] = 14,
	[15] = 17,
	[16] = 17
}, {
	-- mm7
	[0] = { 2, 3 },
	[1] = { 2, 3 },
	[4] = { 6, 7 },
	[5] = { 6, 7 },
	[8] = { 10, 11 },
	[9] = { 10, 11 },
	[12] = { 14, 15 },
	[13] = { 14, 15 },
	[16] = { 18, 19 },
	[17] = { 18, 19 },
	[20] = { 22, 23 },
	[21] = { 22, 23 },
	[24] = { 26, 27 },
	[25] = { 26, 27 },
	[28] = { 30, 31 },
	[29] = { 30, 31 },
	[32] = { 34, 35 },
	[33] = { 34, 35 }
}, {
	-- mm8
	[0] = 1,
	[2] = 3,
	[4] = 5,
	[6] = 7,
	[8] = 9,
	[10] = 11,
	[12] = 13,
	[14] = 15
}, {
	-- mmmerge
	[0] = { 2, 3 },
	[1] = { 2, 3 },
	[4] = { 6, 7 },
	[5] = { 6, 7 },
	[8] = { 9, 9 },
	[10] = { 11, 11 },
	[12] = { 15, 14 },
	[13] = { 15, 14 },
	[16] = { 19, 18 },
	[17] = { 19, 18 },
	[20] = { 21, 21 },
	[22] = { 24, 25 },
	[23] = { 24, 25 },
	[26] = { 28, 29 },
	[27] = { 28, 29 },
	[30] = { 33, 32 },
	[31] = { 33, 32 },
	[34] = { 37, 36 },
	[35] = { 37, 36 },
	[38] = { 39, 39 },
	[40] = { 41, 41 },
	[42] = { 46, 45 },
	[43] = { 46, 45 },
	[44] = { 45, 45 },
	[50] = { 6, 7 },
	[51] = { 45, 46 }
})

--- Returns the maximum class promotion for a given class and light/dark path
--- (For MM7 or MMMerge, promotions are in {light, dark} pairs; for others, it's a single value)
-- @param class (number) The base class ID to look up
-- @param is_dark (boolean) Optional. If false (default), returns the light promotion; if true, returns the dark
-- @return (number|nil) The max class ID for the given input, or nil if not found
function M.max_class(class, is_dark)
	-- Default is_light to true if not provided
	if is_dark == nil then
		is_dark = false
	end
	if not class_promotion then
		return nil
	end
	local value = class_promotion[class]
	if not value then
		return nil
	end
	if type(value) == "table" then
		return is_dark and value[2] or value[1]
	else
		return value
	end
end

--- Calculate character level from experience points (exp = level * (level - 1) * 500)
-- @param exp_value number Total experience points
-- @return number Character level (1-based)
function M.exp_to_level(exp_value)
	return math.floor(math.sqrt(exp_value / 500 + 1 / 4) - 1 / 2) + 1
end

--- Calculate experience points required for a given level (exp = level * (level - 1) * 500)
-- @param level number Character level (1-based)
-- @return number Required experience points
function M.level_to_exp(level)
	return level * (level - 1) * 500
end

--- Calculate moon phase based on day of month (1-28)
-- @param date number Day of month (1-28)
-- @return string Moon phase ("New", "Quarter", "Half", "Three Quarter", or "Full")
function M.date_to_moonphase(date)
	if date >= 1 and date <= 3 then
		return i18n._("moon_phase_new")
	elseif date >= 4 and date <= 7 or date >= 25 and date <= 28 then
		return i18n._("moon_phase_quarter")
	elseif date >= 8 and date <= 10 or date >= 22 and date <= 24 then
		return i18n._("moon_phase_half")
	elseif date >= 11 and date <= 14 or date >= 18 and date <= 21 then
		return i18n._("moon_phase_three_quarter")
	else -- 15-17
		return i18n._("moon_phase_full")
	end
end

--- Calculate day of week based on day of month (1-28)
-- @param date number Day of month (1-28)
-- @return string Day of week ("Monday" through "Sunday")
function M.date_to_dayofweek(date)
	local day_of_week = (date - 1) % 7
	local day_names = { i18n._("monday"), i18n._("tuesday"), i18n._("wednesday"), i18n._("thursday"), i18n._("friday"),
		i18n._("saturday"), i18n._("sunday") }
	return day_names[day_of_week + 1]
end

--- Calculate the score you would get if you finish the game at a specific time
--- Note: time exiting the Hive + 10min is used by mm6 (not sure about 7 and 8), this extra time is not calculated here, but otherwise the calculation should be precise, including edge cases
function M.get_score(timestamp)
	local days = math.floor((timestamp - 138240) / const.Day) -- 138240 is timestamp of Game Start (9:00 epoch day)
	if days < 0 then
		return 0
	elseif days == 0 then
		days = 1
	end
	local exp
	if Game.Version == 6 or Game.Version == 7 then
		exp = Party[0].Experience + Party[1].Experience + Party[2].Experience + Party[3].Experience
	elseif Game.Version == 8 then
		exp = Party.PlayersArray[0].Experience
	end
	return math.floor(exp / days)
end

--- Convert reputation points to a descriptive string based on game version
-- @param pts number The reputation points to convert
-- @return string The reputation description
function M.rep_to_desc(pts)
	local ret = nil
	if Game.Version == 6 then
		if pts >= 1000 then
			ret = "Saintly"
		elseif pts >= 800 then
			ret = "Angelic"
		elseif pts >= 600 then
			ret = "Glorious"
		elseif pts >= 400 then
			ret = "Honorable"
		elseif pts >= 200 then
			ret = "Respectable"
		elseif pts >= 0 then
			ret = "Average"
		elseif pts >= -299 then
			ret = "Bad"
		elseif pts >= -599 then
			ret = "Vile"
		elseif pts >= -799 then
			ret = "Despicable"
		elseif pts >= -999 then
			ret = "Monstrous"
		else
			ret = "Notorious"
		end
	else
		if Game.Version == 7 or Game.Version == 8 then
			if pts <= -25 then
				ret = "Hated"
			elseif pts <= -6 then
				ret = "Unfriendly"
			elseif pts <= 5 then
				ret = "Neutral"
			elseif pts <= 24 then
				ret = "Friendly"
			else
				ret = "Liked"
			end
		end
	end
	if ret ~= nil then
		ret = M.text_to_globaltxt(ret)
	end
	return ret
end

function M.get_mastery_array(no_not_learned)
	local mastery = { i18n._("not_learned"), i18n._("novice"), i18n._("expert"), i18n._("master") }
	if Game.Version ~= 6 then
		table.insert(mastery, i18n._("grand_master"))
	end
	if no_not_learned then
		table.remove(mastery, 1)
	end
	return mastery
end

function M.get_char_name_array(no_empty)
	-- Initialize array to store character names
	local char_names = {}

	if no_empty then
		char_names[1] = i18n._("empty")
	end

	-- Get names from Party.PlayersArray if it exists
	if Party and Party.PlayersArray then
		for i = 0, #Party.PlayersArray do
			local char = Party.PlayersArray[i]
			if char and char.Name then
				char_names[#char_names + 1] = M.format_character_info(char)
			end
		end
	end
	return char_names
end

local LootedCorpseDisapProbAddr = M.mm678(0x421999, 0x426DB6, 0x4251F2)

function M.GetLootedCorpseDisapProb()
	return mem.u1[LootedCorpseDisapProbAddr]
end

function M.SetLootedCorpseDisapProb(chance)
	if LootedCorpseDisapProbAddr then
		mem.IgnoreProtection(true)
		mem.u1[LootedCorpseDisapProbAddr] = chance
		mem.IgnoreProtection(false)
	end
end

function M.format_character_info(char)
	return enc.decode(char.Name) .. i18n._("left_paren") .. i18n._("level"):lower() .. " " .. char.LevelBase .. " " ..
		enc.decode(Game.ClassNames[char.Class]) .. i18n._("right_paren")
end

function M.format_item_info(item)
	if item.Name == '' and item.NotIdentifiedName == '' then
		return ''
	end
	return enc.decode(item.Name) .. i18n._("left_paren") .. enc.decode(item.NotIdentifiedName) .. i18n._("right_paren")
end

function M.CastSpellDirect(SpellId, Skill, Mastery, Caster, Target, Flags, TargetKind)
	if Game.Version == 8 then
		if CastSpellDirect then
			CastSpellDirect(SpellId, Skill, Mastery, Caster, Target, Flags, TargetKind)
		else
			-- The following code is from MM Merge
			local spells_with_inventory_screen = {
				[4] = 0,
				[28] = 0,
				[30] = 0,
				[91] = 0
			}
			if spells_with_inventory_screen[SpellId] then
				return
			end

			Caster = Caster or 49
			if Caster == 49 then
				local pl = Party.PlayersArray[Caster]
				pl.SP = 1000
				pl.DivineInterventionCasts = 0
				pl.ArmageddonCasts = 0
				pl.AgeBonus = 0
			end

			mem.u2[0x51d820] = SpellId
			mem.u2[0x51d822] = Caster -- Caster - rosterId
			mem.u2[0x51d824] = Target or 49 -- Target - rosterId
			mem.u2[0x51d828] = Flags or 0x8020
			mem.u2[0x51d82a] = JoinSkill(Skill or 1, Mastery or 0)
			mem.u2[0x51d82c] = bit.lshift(Target or 0, 3) + (TargetKind or 4)
		end
	end
end

function M.set_fog(on)
	if Game.Weather.Fog and on == false then
		Game.Weather.Fog = false
	elseif not Game.Weather.Fog and on == true then
		Game.Weather.SetFog(M.mm678(0, 4096, 1024), M.mm678(2048, 8192, 18000))
	end
end

--- Add an item to a character's inventory
-- @param char_index number The index of the character in Party.PlayersArray
-- @param props table table containing item properties to override defaults. Can include:
--   - Number: Item ID
--   - Bonus: Standard bonus ID
--   - BonusStrength: Standard bonus strength
--   - Bonus2: Special bonus ID
--   - Charges: Number of charges
--   - Identified: Whether item is identified
--   - Stolen: Whether item is stolen
--   - Broken: Whether item is broken
--   - Hardened: Whether item is hardened
-- @return 1-based item slot index if item was successfully added to that slot, nil if unsuccessful
function M.add_item(char_index, props)
	local char = Party.PlayersArray[char_index]
	if not char then
		return nil
	end

	-- Find first empty item slot (1-based)
	local empty_item_slot = nil
	for i = 1, char.Items.Count do
		if char.Items[i].Number == 0 then
			empty_item_slot = i
			break
		end
	end

	-- Find first empty inventory slot (0-based)
	local empty_inv_slot = nil
	for i = 0, char.Inventory.Count - 1 do
		if char.Inventory[i] == 0 then
			empty_inv_slot = i
			break
		end
	end

	-- Return nil if no empty slots found
	if not empty_item_slot or not empty_inv_slot or not props or props.Number == 0 then
		return nil
	end

	-- Override with provided properties
	-- Set the item in the empty slot
	local item = char.Items[empty_item_slot]

	-- Set default item properties
	item.BodyLocation = 0
	item.Bonus = 0
	item.Bonus2 = 0
	item.BonusExpireTime = 0
	item.BonusStrength = 0
	item.Broken = false
	item.Charges = 0
	item.Condition = 1
	item.Hardened = false
	item.Identified = true
	item.MaxCharges = 0
	item.Number = 0
	item.Owner = 0
	item.Refundable = false
	item.Stolen = false
	item.TemporaryBonus = false

	for k, v in pairs(props) do
		item[k] = v
	end

	-- Set the inventory slot (0-based index) to point to the item slot (1-based index)
	char.Inventory[empty_inv_slot] = empty_item_slot

	return empty_item_slot
end

--- Remove an item from a character's inventory or equipment
-- @param char_index number The index of the character in Party.PlayersArray
-- @param item_index number The 1-based index of the item to remove in the character's Items array
-- @return boolean|nil Returns true if the item was successfully removed, false if the item was found in .Items list but couldn't be found in .Inventory list or .EquippedItems list (in this case, the item in .Items list will be emptied), or nil if the character or item doesn't exist
function M.remove_item(char_index, item_index)
	local char = Party.PlayersArray[char_index]
	if not char then
		return nil
	end

	-- Find its main inventory slot (0-based)
	local inv_slot = nil
	for i = 0, char.Inventory.Count - 1 do
		if char.Inventory[i] == item_index then
			inv_slot = i
			break
		end
	end

	if inv_slot then
		char:RemoveFromInventory(inv_slot) -- item is removed from both .Inventory and .Items
		return true
	end
	-- Can't find main inventory slot, very likely equipped and not in inventory
	-- Empty the item in any case
	local target_item = char.Items[item_index]
	if not target_item then
		return nil
	end

	target_item.BodyLocation = 0
	target_item.Bonus = 0
	target_item.Bonus2 = 0
	target_item.BonusExpireTime = 0
	target_item.BonusStrength = 0
	target_item.Broken = false
	target_item.Charges = 0
	target_item.Condition = 1
	target_item.Hardened = false
	target_item.Identified = true
	target_item.MaxCharges = 0
	target_item.Number = 0
	target_item.Owner = 0
	target_item.Refundable = false
	target_item.Stolen = false
	target_item.TemporaryBonus = false

	-- Try to remove it from equipped list if found
	for j = 0, char.EquippedItems.Count - 1 do
		if char.EquippedItems[j] == item_index then
			char.EquippedItems[j] = 0
			return true
		end
	end
	return false
end

function M.get_spell_local_name(spell_const_name)
	local index = const.Spells[spell_const_name]
	if not index then
		return nil
	end
	local spell = Game.SpellsTxt[index]
	if not spell then
		return nil
	end
	return enc.decode(spell.Name)
end

function M.EnableAllTownPortalQbits()
	local qbits = {}
	for i = M.mm67or8(206, 180), M.mm67or8(211, 185) do
		table.insert(qbits, i)
	end
	if Merge ~= nil then
		for i = 1, 3 do
			local sets = TownPortalControls.Sets[i]
			for j = 1, #sets do
				table.insert(qbits, sets[j].QBI)
			end
		end
	end
	for _, qbit in ipairs(qbits) do
		Party.QBits[qbit] = true
	end
end

-- Shallow comparison function for two values
function M.shallow_equal(a, b)
	-- Handle exact equality (including nil, numbers, strings, booleans)
	if a == b then
		return true
	end

	-- If types are different, they're not equal
	if type(a) ~= type(b) then
		return false
	end

	-- Handle tables with shallow comparison
	if type(a) == "table" then
		-- Check if both tables have the same number of key-value pairs
		local count_a, count_b = 0, 0

		-- Count keys in table a and compare values
		for k, v in pairs(a) do
			count_a = count_a + 1
			if b[k] ~= v then
				return false
			end
		end

		-- Count keys in table b
		for k, v in pairs(b) do
			count_b = count_b + 1
		end

		-- Tables are equal if they have the same number of keys
		return count_a == count_b
	end

	-- For other types (functions, userdata, threads), use reference equality
	return false
end

-- Main function to check if obj exists in arr
function M.exists_in(arr, obj)
	for i = 1, #arr do
		if M.shallow_equal(arr[i], obj) then
			return true
		end
	end
	return false
end

------------------ Map related functions ------------------
-- Table of special filenames that need prefix removal for version 7
local special_mapfiles = { "d01.blv", "d02.blv", "d03.blv", "d04.blv", "out09.odm", "out10.odm", "out11.odm",
	"out12.odm", "out14.odm", "t01.blv", "t02.blv", "t03.blv", "t04.blv" }

-- Decide MM6/7 map filename should use prefix or not to match mmmerge's map filename
-- @param version number 6 or 7
-- @param filename string map filename without version prefix
local function map_filename_67_to_merge(version, filename)
	local no_prefix = false

	-- Check conditions for version 6
	if version == 6 then
		-- Remove prefix if filename doesn't start with 'd' or 't'
		no_prefix = not (filename:sub(1, 1) == "d" or filename:sub(1, 1) == "t")
		-- Check conditions for version 7
	elseif version == 7 then
		-- Remove prefix if filename starts with 'm' or is in special files list
		no_prefix = filename:sub(1, 1) == "m"
		if not no_prefix then
			for _, special_file in ipairs(special_mapfiles) do
				local filename_without_extension = filename:match("^(.*)%.([^%.]*)$") or filename
				local special_file_without_extension = special_file:match("^(.*)%.([^%.]*)$") or special_file
				if filename_without_extension == special_file_without_extension then
					no_prefix = true
					break
				end
			end
		end
	end

	if no_prefix then
		return filename
	end
	return version .. filename
end

-- Convert mm6/7/8/merge's map filename so it can match the exact corresponding lowercase map filename in mmmerge
-- Filenames have no extension here
function M.normalize_map_filename(incoming_filename)
	local incoming = incoming_filename:lower()
	local version = Game.Version
	if version == 6 or version == 7 then
		incoming = map_filename_67_to_merge(version, incoming)
	end
	return incoming
end

-- User-pasted map filename compared with in-game mapname in mm6/7/8/merge
-- If user copied a MM6/7 map filename and want it work in mmmerge, they should manually add a prefix '6' or '7' to the filename, and it will work perfectly in mmmerge thanks to this function
-- Map filename copied from mmmerge will work perfectly in mm6/7/8 without manual adjustment
-- Filenames all have extension
function M.compare_map_filename(in_game_filename, incoming_filename)
	-- Convert both filenames to lowercase for comparison (map filename is case insensitive)
	local in_game = in_game_filename:lower()
	local incoming = incoming_filename:lower()

	-- Check if we need to handle version-specific logic
	if Game.Version == 6 or Game.Version == 7 then
		-- Remove version prefix from incoming filename if it exists
		local version_prefix = tostring(Game.Version)
		if incoming:sub(1, 1) == version_prefix then
			incoming = incoming:sub(2)
		end
	end

	-- Handle Merge case
	if Merge ~= nil then
		local version = tonumber(incoming:sub(1, 1))
		if version == 6 or version == 7 then
			local filename_without_prefix = incoming:sub(2)
			incoming = map_filename_67_to_merge(version, filename_without_prefix)
		end
	end

	return in_game == incoming
end

-- Extract coordinate values from text
function M.extract_coordinate_values(coord_text)
	-- Strip inline comments (anything after ;, #, or //)
	coord_text = coord_text:match("^(.-)%s*[%;%#]") or coord_text
	coord_text = coord_text:match("^(.-)%s*//") or coord_text

	-- Remove whitespace and unify quote styles
	coord_text = coord_text:gsub("%s+", ""):gsub('"', "'")

	-- Match only valid numbers (optionally negative, no decimal part)
	local number_pattern = "(-?%d+)"

	-- Extract values with strict matching, case insensitive
	local x = coord_text:match("[Xx]=" .. number_pattern)
	local y = coord_text:match("[Yy]=" .. number_pattern)
	local z = coord_text:match("[Zz]=" .. number_pattern)
	local dir = coord_text:match("[Dd]irection=" .. number_pattern)
	local angle = coord_text:match("[Ll]ook[Aa]ngle=" .. number_pattern)
	local name = coord_text:match("[Nn]ame='([^']+)'")

	return {
		X = x and tonumber(x),
		Y = y and tonumber(y),
		Z = z and tonumber(z),
		Direction = dir and tonumber(dir),
		LookAngle = angle and tonumber(angle),
		Name = name
	}
end

function M.truncate(str, limit)
	limit = limit or 45
	if #str > limit then
		local cut = math.max(limit - 3, 1)
		return str:sub(1, cut) .. "..."
	else
		return str
	end
end

-- Format coordinate text
-- @param coord table table containing coordinate values
-- @param type string type of format
-- @return string formatted coordinate text
function M.format_coordinate_text(coord, type)
	local x = coord.X
	local y = coord.Y
	local z = coord.Z
	local dir = coord.Direction
	local angle = coord.LookAngle
	local name = coord.Name
	local comment = coord.Comment
	if type == "short" then
		return string.format("X%s,Y%s,Z%s,D%s,A%s", x, y, z, dir, angle)
	elseif type == "bookmark_display" then
		local mapname = M.mapconv.filename_to_name(name)
		local short = M.format_coordinate_text(coord, "short")
		local comment_same_as_mapname = comment and comment == mapname
		comment = comment and comment ~= "" and M.truncate(comment) or i18n._("empty")
		local s = comment
		if not comment_same_as_mapname then
			s = s .. " - " .. mapname
		end
		return string.format("%s (%s)", s, short)
	elseif type == "coords_txt" then
		local long = M.format_coordinate_text(coord)
		if comment and comment ~= "" then
			long = long .. " ; " .. comment
		end
		return long
	elseif type == "mapname_and_short" then
		local mapname = M.mapconv.filename_to_name(name)
		local short = M.format_coordinate_text(coord, "short")
		return string.format("%s (%s)", mapname, short)
	elseif type == "short_and_mapname" then
		local mapname = M.mapconv.filename_to_name(name)
		local short = M.format_coordinate_text(coord, "short")
		return string.format("%s (%s)", short, mapname)
	else
		return string.format("X=%s,Y=%s,Z=%s,Direction=%s,LookAngle=%s,Name='%s'", x, y, z, dir, angle, name)
	end
end

M.mapconv = {
	map_filenames = {},
	map_names = {},
	is_outdoors = {},
	map_select_options = {}
}

function M.mapconv.is_outdoor(filename)
	if not filename then
		return nil
	end
	local ext = filename:match("^.+%.([^.]+)$")
	if ext then
		ext = ext:lower()
	else
		return nil
	end
	if ext == "odm" or ext == "ddm" then
		return true
	end
	return false
end

function M.mapconv.init()
	if #M.mapconv.map_filenames > 0 then
		return
	end
	M.mapconv.map_filenames = {}
	M.mapconv.map_names = {}
	M.mapconv.map_select_options = {}
	for _, map in Game.MapStats do
		if map.Name and map.Name ~= "" then
			local map_filename = map.FileName
			local map_name = enc.decode(map.Name)
			local map_select_option = map_name .. i18n._("left_paren") .. map_filename .. i18n._("right_paren")
			table.insert(M.mapconv.map_filenames, map_filename)
			table.insert(M.mapconv.map_names, map_name)
			table.insert(M.mapconv.map_select_options, map_select_option)
		end
	end
end

function M.mapconv.cleanup()
	M.mapconv.map_filenames = {}
	M.mapconv.map_names = {}
	M.mapconv.is_outdoors = {}
	M.mapconv.map_select_options = {}
end

states.register_cleanup(M.mapconv.cleanup)

function M.mapconv.is_outdoor_by_index(index)
	if type(index) == "string" then
		index = tonumber(index)
	end
	return M.mapconv.is_outdoor(M.mapconv.index_to_filename(index))
end

function M.mapconv.index_to_filename(index)
	if type(index) == "string" then
		index = tonumber(index)
	end
	return M.mapconv.map_filenames[index]
end

function M.mapconv.filename_to_index(filename)
	for i, map_filename in ipairs(M.mapconv.map_filenames) do
		if M.compare_map_filename(map_filename, filename) then
			return i
		end
	end
end

function M.mapconv.filename_to_name(filename)
	for i, map_filename in ipairs(M.mapconv.map_filenames) do
		if M.compare_map_filename(map_filename, filename) then
			return M.mapconv.map_names[i]
		end
	end
end

-- coords.txt is a text file, each line is a set of coordinates, each set of coordinates is a string like "X=4790,Y=27279,Z=-2255,Direction=0,LookAngle=0,Name='Hive.Blv'", could have ";" or "#" at the end of line as comments to the end of the line that is not part of the coordinate. Empty line is ignored.
local coords_txt_path = "Scripts/Modules/MMCheat/coords.txt"

-- Read coords.txt and return an array of {X=,Y=,Z=,Direction=,LookAngle=,Name=}
function M.read_coords_txt()
	local coords = {}
	if ini.file_exists(coords_txt_path) then
		local file = io.open(coords_txt_path, "r")
		if not file then
			return {}
		end
		local line = file:read("*line")
		while line do
			-- Match a comment starting with ; or # and capture everything after it
			local comment = line:match("[;#](.*)$")
			if comment then
				-- Trim leading and trailing whitespace
				comment = comment:match("^%s*(.-)%s*$")
			end
			local coord_table = M.extract_coordinate_values(line)
			if comment and comment ~= "" then
				coord_table.Comment = comment
			end
			-- if {X,Y,Z,Direction,LookAngle,Name} at least one value is not nil, insert it into coords
			if coord_table.X or coord_table.Y or coord_table.Z or coord_table.Direction or coord_table.LookAngle or
				coord_table.Name then
				table.insert(coords, coord_table)
			end
			line = file:read("*line")
		end
		file:close()
	end
	return coords
end

function M.write_coords_txt(coords)
	-- the following line creates the file if it doesn't exist
	local file = io.open(coords_txt_path, "w")
	if not file then
		return
	end
	for _, coord in ipairs(coords) do
		file:write(M.format_coordinate_text(coord, "coords_txt") .. "\n")
	end
	file:close()
end

-- Deduplicate coords, return the number of deduplicated coords (the returned coords could be the same as the original coords if no dedup is needed, you can use `#unique_coords == #coords` to check if no dedup is needed) (comment field is also compared)
function M.dedup_coords(coords)
	local unique_coords = {}
	for _, coord in ipairs(coords) do
		if not M.exists_in(unique_coords, coord) then
			table.insert(unique_coords, coord)
		end
	end
	return unique_coords
end

-- Move the item at index to the target index, if is_back is true, move the item to the previous index, otherwise move the item to the next index
-- return the new index of the item, if the item is moved out of bounds, return nil
function M.move_item(array, index, is_back)
	is_back = is_back or false
	local target_index = is_back and index - 1 or index + 1

	-- Check bounds
	if index < 1 or index > #array then
		return nil
	end
	if target_index < 1 or target_index > #array then
		return nil
	end

	-- Swap items
	array[index], array[target_index] = array[target_index], array[index]
	return target_index
end

function M.get_dir(path)
	-- Find the last slash, whether / or \
	local pos1 = path:match("^.*()/") or 0
	local pos2 = path:match("^.*()\\") or 0
	local pos = math.max(pos1, pos2)
	if pos > 0 then
		return path:sub(1, pos)
	else
		return "" -- no directory part found
	end
end

function M.get_map_cut(old_height)
	return {
		top = 77,
		right = 80,
		bottom = old_height == 510 and 78 or 80,
		left = 77
	}
end

M.map_image_size = 355

function M.parse_command(input)
	local tokens = {}

	-- Tokenize the input by whitespace
	for token in string.gmatch(input, "%S+") do
		table.insert(tokens, token)
	end

	-- Extract command name
	local command_name = tokens[1]

	-- Helper function to parse boolean, number, or nil ("_")
	local function parse_arg(token)
		if token == nil or token == "_" then
			return nil
		elseif token == "true" then
			return true
		elseif token == "false" then
			return false
		else
			-- try convert to number, or return nil if fail
			return tonumber(token)
		end
	end

	local arg1 = parse_arg(tokens[2])
	local arg2 = parse_arg(tokens[3])
	local arg3 = parse_arg(tokens[4])

	return command_name, arg1, arg2, arg3
end

return M
