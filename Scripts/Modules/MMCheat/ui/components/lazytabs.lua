local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local states = require("MMCheat/util/states")

local function lazytabs(children, attrs, first_tab_is_not_loaded_when_created)
	local tab_contents = {}
	local tab_info = {}

	-- Create initial tab contents
	for i, module in ipairs(children) do
		table.insert(tab_contents, module.create(i))
		if not tab_info[module] then
			tab_info[module] = {}
		end
		tab_info[module].tab_index = i
	end

	local tabs = ui.tabs(tab_contents, attrs)

	-- First tab is already loaded at start (and note that its firstload is never called! unless you call it manually)
	-- first_tab_is_not_loaded_when_created is usually true when they are subtabs placed in non-first top-level tabs. In this case, manually set `tab_info[tabs[1]].loaded = true` (or `states.set_charsubtab_loaded(tabs[1], true)`) in `function M.firstload()`
	if not first_tab_is_not_loaded_when_created then
		local first_tab_module = children[1]
		if first_tab_module.firstload then
			first_tab_module.firstload()
		end
		if not tab_info[first_tab_module] then
			tab_info[first_tab_module] = {}
		end
		tab_info[first_tab_module].loaded = true
	end

	-- Set up tab change callback
	iup.SetCallback(tabs, "TABCHANGE_CB", function()
		collectgarbage("collect")
		local current_pos = iup.GetInt(tabs, "VALUEPOS") + 1
		local current_module = children[current_pos]

		if not tab_info[current_module].loaded then
			tab_info[current_module].loaded = true
			-- Check if the current tab has a firstload function and hasn't been loaded yet
			if current_module.firstload then
				current_module.firstload(current_pos)
				-- If tab has been loaded before and has a load function, call it
			end
		elseif current_module.reload then
			current_module.reload(current_pos)
		end

		return iup.DEFAULT
	end)

	local function cleanup()
		for _, module in ipairs(children) do
			if module.cleanup then
				module.cleanup()
			end
		end
	end
	states.register_cleanup(cleanup)

	return tabs, tab_info
end

return lazytabs
