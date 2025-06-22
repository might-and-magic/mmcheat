local M = {}
local iup = require("iup")
local ini = require("MMCheat/util/general/ini")
local settings = require("MMCheat/util/settings")
local langs = require("MMCheat/i18n/langs")

local fallback_lang = "en"
local fallback_game_encoding = "windows1252"

local current_lang = fallback_lang
local current_game_encoding = fallback_game_encoding

function M.set_lang(lang_code)
	current_lang = lang_code

	for _, lang in ipairs(langs) do
		if lang.code == lang_code then
			local lang_name_upper = string.upper(lang.loc)
			iup.SetLanguage(lang_name_upper)
			break
		end
	end

	local success, lang_strings = pcall(require, "MMCheat/i18n/str/" .. lang_code)
	if success and lang_strings then
		for key, value in pairs(lang_strings) do
			iup.SetLanguageString(key, value)
		end
	end
end

function M.get_lang()
	return current_lang
end

function M.set_game_encoding(encoding)
	current_game_encoding = encoding
end

function M.get_game_encoding()
	return current_game_encoding
end

local str1MapToLang = {
	["4163637572616379"] = "en",
	["5072E9636973696F6E"] = "fr",
	["44657874E9726974E9"] = "fr",
	["476573636869636B"] = "de",
	["47656E617569676B656974"] = "de",
	["50726563697369F36E"] = "es",
	["507265636973696F6E65"] = "it",
	["41636375726174657A7A61"] = "it",
	["50F865736E6F7374"] = "cs",
	["43656C6E6F9CE6"] = "pl",
	["CCE5F2EAEEF1F2FC"] = "ru",
	["C1A4C8AEBCBA"] = "ko",
	["8AED97709378"] = "ja"
}

local function to_hex(str)
	return (str:gsub('.', function(c)
		return string.format('%02X', string.byte(c))
	end))
end

local function GetLangFromLocalizeConf()
	local LocalizeConfPath = "Data/LocalizeConf.ini"
	local lang, encoding
	if ini.file_exists(LocalizeConfPath) then
		local ini_content = ini.read(LocalizeConfPath)
		if ini_content and ini_content.Settings then
			lang = ini_content.Settings.lang
		end
	end
	return lang
end

function M.detect_lang()
	local str1 = Game.GlobalTxt[1]
	if DBCS and DBCS.decodeSpecial then
		str1 = DBCS.decodeSpecial(str1)
	end
	str1 = to_hex(str1)
	local lang = str1MapToLang[str1]
	if DBCS then
		lang = GetLangFromLocalizeConf()
	end
	if not lang then
		local dbc1 = string.sub(str1, 1, 4)
		local dbc2 = string.sub(str1, 5, 8)
		-- 1st is 准D7BC (zh_CN) / 準B7C7 (zh_TW) or 2nd is 确C8B7 (zh_CN) / 確BD54 (zh_TW)
		-- 1st and 2nd is 命C3FC and 中D6D0 (zh_CN)
		if dbc1 == "D7BC" then
			lang = "zh_CN"
		elseif dbc1 == "B7C7" then
			lang = "zh_TW"
		elseif dbc2 == "C8B7" then
			lang = "zh_CN"
		elseif dbc2 == "BD54" then
			lang = "zh_TW"
		elseif dbc1 == "C3FC" and dbc1 == "D6D0" then
			lang = "zh_CN"
		end
	end
	return lang
end

function M.detect_game_encoding()
	local lang_code = M.detect_lang()
	if not lang_code then
		return fallback_game_encoding -- Default
	end
	for _, lang in ipairs(langs) do
		if lang.code == lang_code then
			return lang.encoding
		end
	end
	return fallback_game_encoding -- Default
end

function M.init()
	local lang, game_encoding

	if ini.file_exists(settings.conf_path) then
		local ini_lang_section = ini.read(settings.conf_path).lang
		if ini_lang_section then
			lang = ini_lang_section.lang
			game_encoding = ini_lang_section.game_encoding
		end
	end
	local should_write_ini = false
	if not lang then
		lang = M.detect_lang()
		if not lang then
			return fallback_lang
		end
		should_write_ini = true
	end
	if not game_encoding then
		game_encoding = M.detect_game_encoding()
		should_write_ini = true
	end
	if should_write_ini then
		ini.write(settings.conf_path, {
			lang = {
				lang = lang,
				game_encoding = game_encoding
			}
		}, 1)
	end

	M.set_lang(lang)
	M.set_game_encoding(game_encoding)
end

function M.get_lang_props()
	for _, lang in ipairs(langs) do
		if lang.code == current_lang then
			return lang
		end
	end
	-- If current_lang is not found, return English as fallback
	return langs[1]
end

function M._(key, ...)
	local str = iup.GetLanguageString(key)
	if not str then
		return key
	end
	-- Replace single & with &&, but don't touch existing &&
	-- gsub returns (modified_string, number_of_substitutions)
	-- we only want the modified string
	local result = str:gsub("([^&])&([^&])", "%1&&%2")
	-- If there are additional arguments, use string.format
	if select("#", ...) > 0 then
		result = string.format(result, ...)
	end
	return result
end

return M
