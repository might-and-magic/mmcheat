local ffi = require("ffi")
local i18n = require("MMCheat/i18n/i18n")

local M = {}

ffi.cdef [[
    int MultiByteToWideChar(
        unsigned int CodePage,
        unsigned int dwFlags,
        const char *lpMultiByteStr,
        int cbMultiByte,
        wchar_t *lpWideCharStr,
        int cchWideChar
    );

    int WideCharToMultiByte(
        unsigned int CodePage,
        unsigned int dwFlags,
        const wchar_t *lpWideCharStr,
        int cchWideChar,
        char *lpMultiByteStr,
        int cbMultiByte,
        const char *lpDefaultChar,
        int *lpUsedDefaultChar
    );
]]

local CP_UTF8 = 65001

-- Mapping of encoding name to Windows Code Page ID
local encoding_to_cp = {
	gb2312 = 936,
	gbk = 936, -- GBK is a superset of GB2312, same code page on Windows
	big5 = 950,
	shift_jis = 932,
	euc_jp = 20932,
	euc_kr = 51949,
	windows1250 = 1250,
	windows1251 = 1251,
	windows1252 = 1252,
	windows949 = 949 -- similar to euc_kr
}

-- Readable names
M.encodings = {
	windows1250 = 'Windows-1250',
	windows1251 = 'Windows-1251',
	windows1252 = 'Windows-1252',
	gb2312 = 'GB2312',
	big5 = 'Big5',
	shift_jis = 'Shift JIS',
	euc_kr = 'EUC-KR'
}

--- Converts a multibyte string in a known encoding to UTF-8
-- @param input string (in the source encoding)
-- @param encoding string (e.g. "gb2312", "big5", "shift_jis", "windows1252", etc.)
-- @return UTF-8 string or nil, error
function M.any_to_utf8(input, encoding)
	if input == '' then
		return ''
	end
	if type(input) ~= "string" then
		return input
	end

	local cp = encoding_to_cp[encoding:lower()]
	if not cp then
		return nil, "Unsupported encoding: " .. tostring(encoding)
	end

	local input_len = #input

	-- Step 1: Multibyte to UTF-16
	local wide_len = ffi.C.MultiByteToWideChar(cp, 0, input, input_len, nil, 0)
	if wide_len == 0 then
		return nil, "MultiByteToWideChar failed (length)"
	end

	local wchar_buf = ffi.new("wchar_t[?]", wide_len)
	local r = ffi.C.MultiByteToWideChar(cp, 0, input, input_len, wchar_buf, wide_len)
	if r == 0 then
		return nil, "MultiByteToWideChar failed (conversion)"
	end

	-- Step 2: UTF-16 to UTF-8
	local utf8_len = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wchar_buf, wide_len, nil, 0, nil, nil)
	if utf8_len == 0 then
		return nil, "WideCharToMultiByte failed (length)"
	end

	local utf8_buf = ffi.new("char[?]", utf8_len)
	local r2 = ffi.C.WideCharToMultiByte(CP_UTF8, 0, wchar_buf, wide_len, utf8_buf, utf8_len, nil, nil)
	if r2 == 0 then
		return nil, "WideCharToMultiByte failed (conversion)"
	end

	return ffi.string(utf8_buf, utf8_len)
end

--- Converts UTF-8 string to specified encoding
-- @param input string (UTF-8)
-- @param encoding string (target encoding name)
-- @return encoded string or nil, error
function M.utf8_to_any(input, encoding)
	if input == '' then
		return ''
	end
	if type(input) ~= "string" then
		return input
	end

	local cp = encoding_to_cp[encoding:lower()]
	if not cp then
		return nil, "Unsupported encoding: " .. tostring(encoding)
	end

	local input_len = #input

	-- Step 1: UTF-8 to UTF-16 (wide char)
	local wide_len = ffi.C.MultiByteToWideChar(CP_UTF8, 0, input, input_len, nil, 0)
	if wide_len == 0 then
		return nil, "MultiByteToWideChar failed (length)"
	end

	local wchar_buf = ffi.new("wchar_t[?]", wide_len)
	local r = ffi.C.MultiByteToWideChar(CP_UTF8, 0, input, input_len, wchar_buf, wide_len)
	if r == 0 then
		return nil, "MultiByteToWideChar failed (conversion)"
	end

	-- Step 2: UTF-16 to target encoding
	local encoded_len = ffi.C.WideCharToMultiByte(cp, 0, wchar_buf, wide_len, nil, 0, nil, nil)
	if encoded_len == 0 then
		return nil, "WideCharToMultiByte failed (length)"
	end

	local encoded_buf = ffi.new("char[?]", encoded_len)
	local r2 = ffi.C.WideCharToMultiByte(cp, 0, wchar_buf, wide_len, encoded_buf, encoded_len, nil, nil)
	if r2 == 0 then
		return nil, "WideCharToMultiByte failed (conversion)"
	end

	return ffi.string(encoded_buf, encoded_len)
end

function M.decode(input)
	local encoding = i18n.get_game_encoding()
	local ret = input
	if DBCS and DBCS.decodeSpecial and DBCS.isSupportedEncoding and DBCS.isSupportedEncoding(encoding) then
		ret = DBCS.decodeSpecial(ret)
	end
	ret = M.any_to_utf8(ret, encoding)
	if ret == nil then
		ret = ""
	end
	return ret
end

function M.encode(input)
	local encoding = i18n.get_game_encoding()
	local ret = input
	ret = M.utf8_to_any(ret, encoding)
	if DBCS and DBCS.encodeSpecial and DBCS.isSupportedEncoding and DBCS.isSupportedEncoding(encoding) then
		ret = DBCS.encodeSpecial(ret, encoding)
	end
	if ret == nil then
		ret = ""
	end
	return ret
end

return M
