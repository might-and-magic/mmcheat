local iup = require("iup")
local ui = require("MMCheat/ui/components/ui_components")
local i18n = require("MMCheat/i18n/i18n")

local M = {}

function M.cleanup()
end

function M.firstload()
end

local function check_i18n_consistency()
	local languages = {
		"cs", "de", "en", "es", "fr", "it", "ja", "ko", "pl", "pt", "ru", "uk", "zh_CN", "zh_TW"
	}

	local language_data = {}
	local reference_keys = nil
	local reference_length = nil

	-- Load all language files
	for _, lang in ipairs(languages) do
		local success, data = pcall(require, "MMCheat/i18n/str/" .. lang)
		if success then
			language_data[lang] = data

			-- Use English as reference
			if lang == "en" then
				reference_keys = {}
				for key, _ in pairs(data) do
					table.insert(reference_keys, key)
				end
				table.sort(reference_keys)
				reference_length = #reference_keys
			end
		else
			print("Failed to load language file: " .. lang)
		end
	end

	-- Check each language against the reference
	local issues = {}

	for lang, data in pairs(language_data) do
		if lang ~= "en" then
			local current_keys = {}
			for key, _ in pairs(data) do
				table.insert(current_keys, key)
			end
			table.sort(current_keys)

			-- Check length
			if #current_keys ~= reference_length then
				table.insert(issues,
					string.format("%s: Length mismatch (expected %d, got %d)", lang, reference_length, #current_keys))
			end

			-- Check for missing keys
			if reference_keys then
				for _, ref_key in ipairs(reference_keys) do
					if data[ref_key] == nil then
						table.insert(issues, string.format("%s: Missing key '%s'", lang, ref_key))
					end
				end
			end

			-- Check for extra keys
			for _, curr_key in ipairs(current_keys) do
				local found = false
				if reference_keys then
					for _, ref_key in ipairs(reference_keys) do
						if curr_key == ref_key then
							found = true
							break
						end
					end
				end
				if not found then
					table.insert(issues, string.format("%s: Extra key '%s'", lang, curr_key))
				end
			end
		end
	end

	-- Display results
	if #issues == 0 then
		print("I18N Check: All language files are consistent!")
		print(string.format("Total keys: %d", reference_length))
		print("All languages have the same structure and keys.")
	else
		print("I18N Check: Found issues:")
		for _, issue in ipairs(issues) do
			print("  " .. issue)
		end
	end

	return #issues == 0, issues
end

function M.create()
	local check_i18n_button = ui.button("Check I18N", nil)

	iup.SetCallback(check_i18n_button, "ACTION", function()
		local success, issues = check_i18n_consistency()
		if success then
			iup.Message("I18N Check", "I18N consistency check passed!")
		else
			iup.Message("I18N Check", "I18N consistency check failed with " .. #issues .. " issues.")
		end
		return iup.DEFAULT
	end)

	local content_table = {
		ui.label("Test"),
		check_i18n_button
	}
	return ui.centered_vbox(content_table, {
		TABTITLE = "Test"
	})
end

return M
