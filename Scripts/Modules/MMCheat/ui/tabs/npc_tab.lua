local ui = require("MMCheat/ui/components/ui_components")
local iup = require("iup")
local utils = require("MMCheat/util/utils")
local i18n = require("MMCheat/i18n/i18n")
local enc = require("MMCheat/i18n/encoding")
local ImageLabel = require("MMCheat/ui/components/ImageLabel")
local facesound = require("MMCheat/util/image/facesound")

local merge_first_street_npc = 1184

local M = {}

local fixed_npc_image_label_obj, fixed_npc_select, hired_fixed_npc_list
local street_npc_name_input, street_npc_prof_select, street_npc_image_input, hired_street_npc_list, street_npc_select, street_npc_talk_button, street_npc_hire_button, street_npc_image_label_obj
local house_select

-- Table to map hired_fixed_npc_list indices to Game.NPC indices (mm6, 7)
local hired_fixed_npc_indices
-- Table to map hired_fixed_npc_list indices to vars.NPCFollowers indices (mmmerge)
local hired_fixed_npc_indices_mmmerge
-- Table to map hired_street_npc_list indices to vars.NPCFollowers indices (mmmerge)
local hired_street_npc_indices_mmmerge
-- Table to map select indices to const.NPCProfession indices
local select_to_const_prof_index

function M.cleanup()
	fixed_npc_image_label_obj, fixed_npc_select, hired_fixed_npc_list = nil
	street_npc_name_input, street_npc_prof_select, street_npc_image_input, hired_street_npc_list, street_npc_select, street_npc_talk_button, street_npc_hire_button, street_npc_image_label_obj = nil
	house_select = nil

	hired_fixed_npc_indices, hired_fixed_npc_indices_mmmerge, hired_street_npc_indices_mmmerge, select_to_const_prof_index = nil
end

local function format_npc_name(npc)
	local name
	if npc then
		name = npc.Name
	end
	if not name then
		name = ""
	end
	name = enc.decode(name)
	if npc.Profession and npc.Profession ~= 0 then
		local prof_name = utils.const_to_globaltxt("NPCProfession", npc.Profession)
		if prof_name and prof_name ~= "" then
			return string.format("%s (%s)", name, prof_name)
		end
	end
	return name
end

local function load_fixed_npc_image(selected)
	if selected and selected ~= 0 then
		local npc = Game.NPC[selected]
		if npc.Pic and npc.Pic ~= 0 then
			fixed_npc_image_label_obj:load_mm_bitmap_filename(
				facesound.get_filename_by_npc_pic_index(npc.Pic),
				{ "cyan", "magenta" }
			)
		else
			fixed_npc_image_label_obj:load_mm_bitmap_filename()
		end
	end
end

local function load_street_npc_image(image_index)
	street_npc_image_label_obj:load_mm_bitmap_filename(
		facesound.get_filename_by_npc_pic_index(image_index),
		{ "cyan", "magenta" }
	)
end

-- npc can be nil where defaults will be set for the fields
local function load_npc_info(npc)
	-- Update input fields with NPC data
	local name
	if npc then
		name = npc.Name
	end
	if not name then
		name = ""
	end
	name = enc.decode(name)
	iup.SetAttribute(street_npc_name_input, "VALUE", name)

	-- Find the select index for the profession
	local prof_select_index = 1 -- Default to [Empty]
	if npc and npc.Profession then
		for i, const_index in pairs(select_to_const_prof_index) do
			if const_index == npc.Profession then
				prof_select_index = i
				break
			end
		end
	end
	utils.select_item_in_select(street_npc_prof_select, prof_select_index)

	local pic
	if npc then
		pic = npc.Pic
	end
	if not pic then
		pic = 0
	end
	iup.SetAttribute(street_npc_image_input, "VALUE", pic)
	load_street_npc_image(pic)
end

local function select_fixed_npc_in_select(npc_index)
	if npc_index then
		utils.select_item_in_select(fixed_npc_select, npc_index)
		load_fixed_npc_image(iup.GetInt(fixed_npc_select, "VALUE"))
	end
end

local function select_street_npc_in_select(npc_index)
	if npc_index and Merge ~= nil then
		-- Convert from Game.NPC index to street_npc_select index
		local select_index = npc_index - merge_first_street_npc + 1
		utils.select_item_in_select(street_npc_select, select_index)
	end
end

local function select_hired_fixed_npc_in_list(npc_index)
	if npc_index then
		-- Find the index in hired_fixed_npc_list
		local list_index
		if Merge == nil then
			for i, idx in ipairs(hired_fixed_npc_indices) do
				if idx == npc_index then
					list_index = i
					break
				end
			end
		else
			for i, idx in ipairs(hired_fixed_npc_indices_mmmerge) do
				if idx == npc_index then
					list_index = i
					break
				end
			end
		end
		if list_index then
			utils.select_item_in_select(hired_fixed_npc_list, list_index)
		end
	end
end

local function select_hired_street_npc_in_list(npc_index)
	if npc_index then
		-- Find the index in hired_street_npc_list
		local list_index
		if Merge == nil then
			list_index = npc_index
		else
			for i, idx in ipairs(hired_street_npc_indices_mmmerge) do
				if idx == npc_index then
					list_index = i
					break
				end
			end
		end
		if list_index then
			utils.select_item_in_select(hired_street_npc_list, list_index)
		end
	end
end

local function load_hired_fixed_npcs(selection)
	local display_names = {}

	if Merge == nil then
		hired_fixed_npc_indices = {}

		-- Loop through NPCs and add hired ones to the list
		for i = 1, Game.NPC.Count - 1 do
			if Game.NPC[i].Hired then
				local display_name = format_npc_name(Game.NPC[i])
				table.insert(display_names, display_name)
				table.insert(hired_fixed_npc_indices, i)
			end
		end
	else
		hired_fixed_npc_indices_mmmerge = {}
		for i = 1, #vars.NPCFollowers do
			if vars.NPCFollowers[i] < merge_first_street_npc then
				table.insert(hired_fixed_npc_indices_mmmerge, vars.NPCFollowers[i])
				local display_name = format_npc_name(Game.NPC[vars.NPCFollowers[i]])
				table.insert(display_names, display_name)
			end
		end
	end

	return utils.load_select_options(hired_fixed_npc_list, display_names, true, selection)
end

local function load_hired_street_npcs(selection)
	-- Remember the previously selected index
	local display_names = {}

	if Merge == nil then
		-- Load the two possible hired street NPCs (mm6, 7)
		for i = 1, 2 do
			local npc = Party.HiredNPC[i]
			if (npc.Name == "" or not npc.Name) and (npc.Pic == 0 or not npc.Pic) then
				table.insert(display_names, i18n._("empty"))
			else
				local display_name = format_npc_name(npc)
				table.insert(display_names, display_name)
			end
		end
	else
		-- Load all street NPCs whose index is vars.NPCFollowers[i] that >= merge_first_street_npc (mmmerge)
		hired_street_npc_indices_mmmerge = {}
		for i = 1, #vars.NPCFollowers do
			if vars.NPCFollowers[i] >= merge_first_street_npc then
				table.insert(hired_street_npc_indices_mmmerge, vars.NPCFollowers[i])
				local display_name = format_npc_name(Game.NPC[vars.NPCFollowers[i]])
				table.insert(display_names, display_name)
			end
		end
	end

	return utils.load_select_options(hired_street_npc_list, display_names, true, selection)
end

local function load_street_npc_select(selection) -- merge-only
	local merge_street_npc_options = {}
	-- Initialize NPC options
	for i = merge_first_street_npc, Game.NPC.Count - 1 do
		table.insert(merge_street_npc_options, format_npc_name(Game.NPC[i]))
	end
	return utils.load_select_options(street_npc_select, merge_street_npc_options, true, selection)
end

local function write_npc_info()
	local selected = iup.GetInt(hired_street_npc_list, "VALUE")
	if selected and selected >= 1 then
		local name = iup.GetAttribute(street_npc_name_input, "VALUE")
		local prof_select_index = iup.GetInt(street_npc_prof_select, "VALUE")
		local image = iup.GetInt(street_npc_image_input, "VALUE")

		-- Trim name and validate all fields
		name = name and name:match("^%s*(.-)%s*$") or ""
		if name == "" or not image or image == 0 or not prof_select_index or prof_select_index == 1 then
			iup.Message(i18n._("warning"), i18n._("must_enter_name_prof_img"))
			return iup.DEFAULT
		end

		-- Update NPC data
		local npc
		if Merge == nil then
			npc = Party.HiredNPC[selected]
		else
			npc = Game.NPC[hired_street_npc_indices_mmmerge[selected]]
		end
		npc.Name = enc.encode(name)
		npc.Profession = select_to_const_prof_index[prof_select_index]
		npc.Pic = image
		npc.Hired = true
		npc.Joins = 1
		npc.TellsNews = 1
		if Merge == nil then
			Party.HiredNPCName[selected] = name
		end

		-- Reload the lists to reflect changes
		load_hired_street_npcs(true)
		if Merge ~= nil then
			local npc_index = hired_street_npc_indices_mmmerge[selected]
			local select_index = npc_index - merge_first_street_npc + 1
			load_street_npc_select(select_index)
		end

		-- Restore the input values
		iup.SetAttribute(street_npc_name_input, "VALUE", name)
		utils.select_item_in_select(street_npc_prof_select, prof_select_index)
		iup.SetAttribute(street_npc_image_input, "VALUE", tostring(image))
		load_street_npc_image(image)
	end
	return iup.DEFAULT
end

local function load_profession_options()
	-- Get all profession names and their values
	local prof_entries = {}

	if Merge == nil then
		for _, value in pairs(const.NPCProfession) do
			table.insert(prof_entries, {
				name = utils.const_to_globaltxt("NPCProfession", value) or "",
				value = value,
			})
		end

		-- Sort by value
		table.sort(prof_entries, function(a, b)
			return a.value < b.value
		end)
	else
		for i = 1, #Game.NPCProfessions do
			if Game.NPCProfessions[i] then
				table.insert(prof_entries, enc.decode(Game.NPCProfessions[i]))
			else
				table.insert(prof_entries, "")
			end
		end
	end

	-- Create mapping and load options
	select_to_const_prof_index = {}
	local prof_options = {}

	-- Add [Empty] as first option
	select_to_const_prof_index[1] = 0
	table.insert(prof_options, i18n._("empty"))

	-- Add other professions
	for i, entry in ipairs(prof_entries) do
		select_to_const_prof_index[i + 1] = entry.value or i
		table.insert(prof_options, entry.name or entry)
	end

	utils.load_select_options(street_npc_prof_select, prof_options)

	utils.select_item_in_select(street_npc_prof_select, 1)
end

function M.firstload()
	-- Load fixed_npc_select
	local fixed_npc_options = {}
	-- Initialize NPC options
	local i_end = utils.mmotherormerge(Game.NPC.Count, merge_first_street_npc) - 1
	for i = 1, i_end do
		table.insert(fixed_npc_options, format_npc_name(Game.NPC[i]))
	end
	utils.load_select_options(fixed_npc_select, fixed_npc_options, false, 1)
	load_fixed_npc_image(iup.GetInt(fixed_npc_select, "VALUE"))

	-- Load street_npc_select
	if Merge ~= nil then
		load_street_npc_select(1)
	end

	local house_options = {}
	-- Initialize house options
	for i = 1, Game.Houses.Count - 1 do
		table.insert(house_options, enc.decode(Game.Houses[i].Name))
	end

	-- Load house_select
	utils.load_select_options(house_select, house_options, false, 1)

	if Game.Version ~= 8 or Merge ~= nil then
		load_profession_options()

		local fixed_npc_selected = load_hired_fixed_npcs(1)
		if fixed_npc_selected > 0 then
			if Merge == nil then
				select_fixed_npc_in_select(hired_fixed_npc_indices[fixed_npc_selected])
			else
				select_fixed_npc_in_select(hired_fixed_npc_indices_mmmerge[fixed_npc_selected])
			end
		end

		local street_npc_selected = load_hired_street_npcs(1)
		if street_npc_selected > 0 then
			if Merge == nil then
				local npc = Party.HiredNPC[street_npc_selected]
				load_npc_info(npc)
			else
				local npc = Game.NPC[hired_street_npc_indices_mmmerge[street_npc_selected]]
				load_npc_info(npc)
				select_street_npc_in_select(hired_street_npc_indices_mmmerge[street_npc_selected])
			end
		end
	end
end

function M.create()
	-- Fixed NPC section
	local fixed_npc_talk_button, fixed_npc_hire_button, fixed_npc_dismiss_button

	fixed_npc_image_label_obj = ImageLabel:new({
		width = facesound.portrait_sizes.npc.width,
		height = facesound.portrait_sizes.npc.height,
	})

	fixed_npc_select = ui.select({})

	fixed_npc_talk_button = ui.button(i18n._("talk"), nil, {
		FGCOLOR = ui.apply_exit_button_color,
		MINSIZE = "60x",
	})

	if Game.Version ~= 8 or Merge ~= nil then
		hired_fixed_npc_list = ui.list({}, nil, {
			SIZE = "180x30",
		})
		fixed_npc_hire_button = ui.button(i18n._("hire"), nil, {
			FGCOLOR = ui.apply_button_color,
			MINSIZE = "60x",
		})
		fixed_npc_dismiss_button = ui.button(i18n._("dismiss"), nil, {
			FGCOLOR = ui.apply_button_color,
			MINSIZE = "60x",
		})
	end

	local street_npc_apply_button, street_npc_dismiss_button
	if Game.Version ~= 8 or Merge ~= nil then
		-- Street NPC section
		street_npc_name_input = ui.input(nil, {
			EXPAND = "HORIZONTAL",
		})
		street_npc_prof_select = ui.select({})
		street_npc_image_input = ui.uint_input(nil, {
			EXPAND = "HORIZONTAL",
		})
		street_npc_apply_button = ui.button(i18n._("apply"), nil, {
			FGCOLOR = ui.apply_button_color,
			MINSIZE = "60x",
		})
		hired_street_npc_list = ui.list({}, nil, {
			SIZE = "180x" .. utils.mmotherormerge("20", "30"),
		})
		street_npc_dismiss_button = ui.button(i18n._("dismiss"), nil, {
			FGCOLOR = ui.apply_button_color,
			MINSIZE = "60x",
		})
		street_npc_image_label_obj = ImageLabel:new({
			width = facesound.portrait_sizes.npc.width,
			height = facesound.portrait_sizes.npc.height,
		})
		if Merge ~= nil then
			street_npc_select = ui.select({}, nil, {
				SIZE = "190x",
				EXPAND = "NO",
			})
			street_npc_talk_button = ui.button(i18n._("talk"), nil, {
				FGCOLOR = ui.apply_exit_button_color,
				MINSIZE = "60x",
			})
			street_npc_hire_button = ui.button(i18n._("hire"), nil, {
				FGCOLOR = ui.apply_button_color,
				MINSIZE = "60x",
			})
		end
	end

	-- House section
	house_select = ui.select({})
	local enter_button = ui.button(i18n._("enter"), nil, {
		FGCOLOR = ui.apply_exit_button_color,
		MINSIZE = "60x",
	})

	-- Set up button click handlers
	iup.SetCallback(fixed_npc_talk_button, "ACTION", function()
		local selected_index = iup.GetInt(fixed_npc_select, "VALUE")
		if selected_index and selected_index ~= 0 then
			local npc = Game.NPC[selected_index]
			if (npc.Name and npc.Name ~= "") or (npc.Pic and npc.Pic ~= 0) then
				evt.SpeakNPC(selected_index)
				return iup.CLOSE
			end
		end
		return iup.DEFAULT
	end)

	if Game.Version ~= 8 or Merge ~= nil then
		iup.SetCallback(fixed_npc_hire_button, "ACTION", function()
			local selected_index = iup.GetInt(fixed_npc_select, "VALUE")
			if selected_index and selected_index ~= 0 then
				if Merge ~= nil then -- mmmerge
					NPCFollowers.Add(selected_index)
					load_hired_fixed_npcs()
					-- Select the newly added NPC
					for i, idx in ipairs(hired_fixed_npc_indices_mmmerge) do
						if idx == selected_index then
							utils.select_item_in_select(hired_fixed_npc_list, i)
							break
						end
					end
				else -- mm6 or 7
					local target = Game.NPC[selected_index]
					if (target.Name and target.Name ~= "") or (target.Pic and target.Pic ~= 0) then
						if Game.Version == 6 and selected_index >= 254 then -- mm6, fixed NPC >= 254 can't be directly added and must be added as street NPC
							local choice = iup.Alarm(
								i18n._("warning"),
								i18n._("mm6_fixed_npc_hire_warning"),
								i18n._("street_npc_slot_1"),
								i18n._("street_npc_slot_2"),
								i18n._("cancel")
							) -- 0: Cancel; 1: Yes, Street NPC slot 1; 2: Yes, Street NPC slot 2; 3: No
							if choice == 1 or choice == 2 then
								local party_npc_index = choice
								local party_npc = Party.HiredNPC[party_npc_index]
								party_npc.Name = target.Name
								party_npc.Pic = target.Pic
								party_npc.Profession = target.Profession
								party_npc.BeggedBefore = target.BeggedBefore
								party_npc.Bits = target.Bits
								party_npc.BribedBefore = target.BribedBefore
								party_npc.Fame = target.Fame
								party_npc.House = target.House
								party_npc.NewsTopic = target.NewsTopic
								party_npc.Rep = target.Rep
								party_npc.Sex = target.Sex
								party_npc.ThreatenedBefore = target.ThreatenedBefore
								party_npc.UsedSpell = target.UsedSpell
								party_npc.Hired = true
								party_npc.Joins = 1
								party_npc.TellsNews = 1
								Party.HiredNPCName[party_npc_index] = target.Name
								-- Reload hired street NPC list to reflect changes
								load_hired_street_npcs(party_npc_index)
								load_npc_info(party_npc)
							end
						else -- mm6 <= 253, or mm7
							Game.NPC[selected_index].Hired = true
							load_hired_fixed_npcs()
							-- Select the newly added NPC
							for i, idx in ipairs(hired_fixed_npc_indices) do
								if idx == selected_index then
									utils.select_item_in_select(hired_fixed_npc_list, i)
									break
								end
							end
						end
					end
				end
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(fixed_npc_dismiss_button, "ACTION", function()
			local selected = iup.GetInt(hired_fixed_npc_list, "VALUE")
			if selected and selected >= 1 then
				if Merge == nil then
					if hired_fixed_npc_indices[selected] then
						Game.NPC[hired_fixed_npc_indices[selected]].Hired = false
						local next_selected = load_hired_fixed_npcs({ true, -1 })
						if next_selected then
							select_fixed_npc_in_select(hired_fixed_npc_indices[next_selected])
						end
					end
				else
					NPCFollowers.Remove(hired_fixed_npc_indices_mmmerge[selected])
					local next_selected = load_hired_fixed_npcs({ true, -1 })
					if next_selected then
						select_fixed_npc_in_select(hired_fixed_npc_indices_mmmerge[next_selected])
					end
				end
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(hired_fixed_npc_list, "VALUECHANGED_CB", function()
			local selected = iup.GetInt(hired_fixed_npc_list, "VALUE")
			if selected and selected >= 1 then
				if Merge == nil then
					select_fixed_npc_in_select(hired_fixed_npc_indices[selected])
				else
					select_fixed_npc_in_select(hired_fixed_npc_indices_mmmerge[selected])
				end
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(fixed_npc_select, "VALUECHANGED_CB", function()
			local selected = iup.GetInt(fixed_npc_select, "VALUE")
			if selected and selected ~= 0 then
				if Merge == nil then
					if Game.NPC[selected].Hired then
						select_hired_fixed_npc_in_list(selected)
					end
				else
					for i, idx in ipairs(hired_fixed_npc_indices_mmmerge) do
						if idx == selected then
							select_hired_fixed_npc_in_list(selected)
							break
						end
					end
				end
			end
			load_fixed_npc_image(selected)
			return iup.DEFAULT
		end)
	end

	if Merge ~= nil then
		iup.SetCallback(street_npc_talk_button, "ACTION", function()
			local selected_index = iup.GetInt(street_npc_select, "VALUE")
			if selected_index and selected_index ~= 0 then
				local index = selected_index + merge_first_street_npc - 1
				local npc = Game.NPC[index]
				if (npc.Name and npc.Name ~= "") or (npc.Pic and npc.Pic ~= 0) then
					evt.SpeakNPC(index)
					return iup.CLOSE
				end
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(street_npc_hire_button, "ACTION", function()
			local selected_index = iup.GetInt(street_npc_select, "VALUE")
			if selected_index and selected_index ~= 0 then
				local index = selected_index + merge_first_street_npc - 1
				NPCFollowers.Add(index)
				load_hired_street_npcs()
				-- Select the newly added NPC
				for i, idx in ipairs(hired_street_npc_indices_mmmerge) do
					if idx == index then
						utils.select_item_in_select(hired_street_npc_list, i)
						break
					end
				end
				load_npc_info(Game.NPC[index])
			end
			return iup.DEFAULT
		end)

		local function reload_npc_info_and_select_mmmerge(selected)
			if selected and selected >= 1 then
				local npc = Game.NPC[hired_street_npc_indices_mmmerge[selected]]
				load_npc_info(npc)
				select_street_npc_in_select(hired_street_npc_indices_mmmerge[selected])
			else
				load_npc_info()
			end
		end

		iup.SetCallback(hired_street_npc_list, "VALUECHANGED_CB", function()
			local selected = iup.GetInt(hired_street_npc_list, "VALUE")
			reload_npc_info_and_select_mmmerge(selected)
			return iup.DEFAULT
		end)

		iup.SetCallback(street_npc_dismiss_button, "ACTION", function()
			local selected = iup.GetInt(hired_street_npc_list, "VALUE")
			if selected and selected >= 1 then
				NPCFollowers.Remove(hired_street_npc_indices_mmmerge[selected])
				local next_selected = load_hired_street_npcs({ true, -1 })
				if next_selected then
					local next_selected_index = next_selected + merge_first_street_npc - 1
					utils.select_item_in_select(hired_street_npc_list, next_selected)
				end
				reload_npc_info_and_select_mmmerge(next_selected)
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(street_npc_select, "VALUECHANGED_CB", function()
			local selected = iup.GetInt(street_npc_select, "VALUE")
			if selected and selected ~= 0 then
				local index = selected + merge_first_street_npc - 1
				for i, idx in ipairs(hired_street_npc_indices_mmmerge) do
					if idx == index then
						select_hired_street_npc_in_list(index)
						load_npc_info(Game.NPC[index])
						break
					end
				end
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(street_npc_apply_button, "ACTION", write_npc_info)
	elseif Game.Version == 6 or Game.Version == 7 then
		-- MM6/7 specific callbacks
		iup.SetCallback(hired_street_npc_list, "VALUECHANGED_CB", function()
			local selected = iup.GetInt(hired_street_npc_list, "VALUE")
			if selected and selected >= 1 and selected <= 2 then
				local npc = Party.HiredNPC[selected]
				load_npc_info(npc)
			end
			return iup.DEFAULT
		end)

		iup.SetCallback(street_npc_apply_button, "ACTION", write_npc_info)

		iup.SetCallback(street_npc_dismiss_button, "ACTION", function()
			local selected = iup.GetInt(hired_street_npc_list, "VALUE")
			if selected and selected >= 1 then
				local npc = Party.HiredNPC[selected]
				-- Reset all NPC properties
				npc.Name = ""
				npc.Pic = 0
				npc.Profession = 0
				npc.BeggedBefore = false
				npc.Bits = 0
				npc.BribedBefore = false
				npc.EventA = 0
				npc.EventB = 0
				npc.EventC = 0
				npc.Fame = 0
				npc.House = 0
				npc.Joins = 0
				npc.NewsTopic = 0
				npc.Rep = 0
				npc.Sex = 0
				npc.TellsNews = 0
				npc.ThreatenedBefore = false
				npc.UsedSpell = 0
				npc.Hired = false
				npc.Exist = false

				Party.HiredNPCName[selected] = ""

				local next_selected = load_hired_street_npcs({ true, -1 })
				if next_selected then
					load_npc_info(Party.HiredNPC[next_selected])
				end
			end
			return iup.DEFAULT
		end)
	end

	if Game.Version ~= 8 or Merge ~= nil then
		iup.SetCallback(street_npc_image_input, "VALUECHANGED_CB", function()
			local pic = iup.GetInt(street_npc_image_input, "VALUE")
			load_street_npc_image(pic)
			return iup.DEFAULT
		end)
	end

	iup.SetCallback(enter_button, "ACTION", function()
		local selected_index = iup.GetInt(house_select, "VALUE")
		if selected_index and selected_index ~= 0 then
			evt.EnterHouse(selected_index)
			return iup.CLOSE
		end
		return iup.DEFAULT
	end)

	-- Create frames with their content
	local fixed_npc_frame
	if Game.Version == 8 and Merge == nil then
		fixed_npc_frame = ui.frame(
			i18n._("fixed_npc"),
			ui.hbox({ fixed_npc_image_label_obj.label, fixed_npc_select, fixed_npc_talk_button })
		)
	else
		fixed_npc_frame = ui.frame(
			i18n._("fixed_npc"),
			ui.hbox({
				fixed_npc_image_label_obj.label,
				ui.vbox({ fixed_npc_select, ui.button_hbox({ fixed_npc_talk_button, fixed_npc_hire_button }) }, {
					ALIGNMENT = "ACENTER",
				}),
				ui.vbox({
					ui.label(i18n._("hired")),
					hired_fixed_npc_list,
					ui.centered_vbox({ fixed_npc_dismiss_button }),
				}),
			})
		)
	end

	local street_npc_frame
	if Game.Version ~= 8 or Merge ~= nil then
		local edit_vbox = ui.vbox(
			{
				ui.labelled_fields(i18n._("name"), { street_npc_name_input }, 0),
				ui.labelled_fields(i18n._("profession"), { street_npc_prof_select }, 0),
				ui.labelled_fields(i18n._("image"), { street_npc_image_input }, 0),
				street_npc_apply_button,
			},
			{
				ALIGNMENT = "ACENTER",
			}
		)
		local hired_list_vbox = ui.vbox({
			ui.label(i18n._("hired")),
			hired_street_npc_list,
			ui.centered_vbox({ street_npc_dismiss_button }),
		})
		local npc_list_vbox
		local street_npc_hbox_content_table
		if Merge ~= nil then
			npc_list_vbox = ui.vbox(
				{ street_npc_select, ui.button_hbox({ street_npc_talk_button, street_npc_hire_button }) },
				{
					ALIGNMENT = "ACENTER",
				}
			)
			street_npc_hbox_content_table =
			{ npc_list_vbox, hired_list_vbox, edit_vbox, street_npc_image_label_obj.label }
		else
			street_npc_hbox_content_table = { street_npc_image_label_obj.label, edit_vbox, hired_list_vbox }
		end
		street_npc_frame = ui.frame(i18n._("street_npc"), ui.hbox(street_npc_hbox_content_table))
	end

	local house_frame = ui.frame(i18n._("house"), ui.hbox({ house_select, enter_button }))

	local content_table = { fixed_npc_frame }
	if Game.Version ~= 8 or Merge ~= nil then
		table.insert(content_table, street_npc_frame)
	end
	table.insert(content_table, house_frame)

	return ui.vbox(content_table, {
		TABTITLE = i18n._("npc"),
		ALIGNMENT = "ACENTER",
	})
end

return M
