-- Global states
local M = {}

local states = {}
local cleanup_handlers = {}

M.logo = nil

-- Register a cleanup function to be called when the application closes
function M.register_cleanup(handler)
	table.insert(cleanup_handlers, handler)
end

-- Execute all registered cleanup functions
function M.execute_cleanup()
	for _, handler in ipairs(cleanup_handlers) do
		pcall(handler) -- Use pcall to prevent one cleanup failure from stopping others
	end
end

function M.cleanup()
	for k in pairs(states) do
		states[k] = nil
	end
	if M.logo then
		M.logo = nil
	end
end

M.register_cleanup(M.cleanup)

-- Set the index of the current character selected in the character select dropdown
function M.set_char_index(char_index)
	states.char_index = char_index
end

-- Get the index of the current character selected in the character select dropdown
function M.get_char_index()
	return states.char_index
end

function M.set_charsubtab_info_table(tab_info)
	states.charsubtab_info = tab_info
end

function M.set_charsubtab_loaded(module, loaded)
	if states.charsubtab_info and states.charsubtab_info[module] then
		states.charsubtab_info[module].loaded = loaded
	end
	return nil
end

function M.get_charsubtab_loaded(module)
	if states.charsubtab_info and states.charsubtab_info[module] then
		return not not states.charsubtab_info[module].loaded
	end
	return false
end

return M
