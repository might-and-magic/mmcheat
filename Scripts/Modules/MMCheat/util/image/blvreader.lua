-- Runtime BLV indoor-map outline extraction.
-- Reads the .blv map file directly from the game's LOD archives (including
-- custom lods added by the GrayFace patch, i.e. any mod's maps) and extracts
-- the automap outline lines, so no pre-captured data file is needed.
--
-- Pipeline (verified in-game):
--   1. Game.GamesLod:FindFile(name, true) - linear search (games lods are not
--      lexicographically sorted); the GrayFace patch hooks this function, so
--      files that live in custom lod archives (e.g. "mm8.games.lod" of a mod)
--      are found too and the returned file stream points into that archive.
--      NOTE: the game's generic LOD-file *loader* (the function behind
--      Game.LoadDataFileFromLod) must NOT be used with games lods - it relies
--      on binary search and terminates the game with a fatal "Unable to open"
--      error when that search misses.
--   2. Game.FileRead of the 16-byte entry header
--      {u4 0x16741, "mvii", u4 compressedSize, u4 uncompressedSize}:
--      compressed entries are self-describing, no directory lookup is needed.
--   3. zlib decompression in pure Lua (util/general/zzlib.lua). Entries
--      without the 'mvii' signature are stored raw (early MM6 archives);
--      their size is resolved from the in-memory lod directories.
--   4. Walk the BLV sections to the Outlines and decode them.
--
-- BLV file layout (validated against all MM6/7/8/Merge maps):
--   0x00  header (0x88 bytes; FacetDataSize @0x68, RoomDataSize @0x6C,
--         RoomLightDataSize @0x70)
--   u4 count + Vertexes  (6 bytes each: i2 X, Y, Z)
--   u4 count + Facets    (0x50 MM6 / 0x60 MM7+8) + FacetDataSize + 10-byte
--                        bitmap name per facet
--   u4 count + FacetData (0x24 each) + 10-byte name per entry
--   u4 count + Rooms     (0x74, MM8 0x78) + RoomDataSize + RoomLightDataSize
--   u4 doors count       (no data in blv)
--   u4 count + Sprites   (0x1C MM6 / 0x20 MM7+8) + 32-byte name per sprite
--   u4 count + Lights    (0xC / 0x10 / 0x14)
--   u4 count + BSPNodes  (8 each)
--   u4 count + Spawns    (0x14 MM6 / 0x18 MM7+8)
--   u4 count + Outlines  (12 bytes: i2 Vertex1, Vertex2, Facet1, Facet2, Z, Bits)
--   (outlines end exactly at end of file - used as a parse sanity check)

local zzlib = require("MMCheat/util/general/zzlib")

local M = {}

local mmver = Game.Version
local function mmv(...)
	return (select(mmver - 5, ...))
end

local REC = {
	facet = mmv(0x50, 0x60, 0x60),
	room = mmv(0x74, 0x74, 0x78),
	sprite = mmv(0x1C, 0x20, 0x20),
	light = mmv(0x0C, 0x10, 0x14),
	spawn = mmv(0x14, 0x18, 0x18),
}

local MAX_COUNT = 1000000  -- sanity limit for section element counts
local MAX_SIZE = 0x4000000 -- sanity limit for file sizes (64 MB)

-- little-endian readers on Lua strings (1-based pos)
local byte = string.byte

local function u32(s, pos)
	local a, b, c, d = byte(s, pos, pos + 3)
	return ((d * 256 + c) * 256 + b) * 256 + a
end

local function u16(s, pos)
	local a, b = byte(s, pos, pos + 1)
	return b * 256 + a
end

local function i16(s, pos)
	local v = u16(s, pos)
	return v >= 0x8000 and v - 0x10000 or v
end

-- shared read buffer for Game.FileRead
local buf, bufsize = nil, 0

local function freadstr(stream, n)
	if n == 0 then
		return ""
	end
	if n > bufsize then
		if buf then
			mem.free(buf)
		end
		buf = mem.malloc(n)
		bufsize = n
	end
	-- element size 1 so the return value is the number of bytes read
	if Game.FileRead(buf, 1, n, stream) ~= n then
		return nil
	end
	return mem.string(buf, n, true)
end

-- Parse a complete decompressed BLV given as a Lua string.
-- Raises on malformed data (call via pcall). Returns
-- {min_x, min_y, max_x, max_y, lines = {{x1=,y1=,x2=,y2=}, ...}}
-- in game coordinates (Y grows north).
local function parse_blv(s)
	local n = #s
	if n < 0x8C then
		error("BLV file too small")
	end
	local facetDataSize = u32(s, 0x68 + 1)
	local roomDataSize = u32(s, 0x6C + 1)
	local roomLightDataSize = u32(s, 0x70 + 1)
	local pos = 0x88 + 1

	local function take_count(what)
		if pos + 3 > n then
			error("BLV truncated at " .. what .. " count")
		end
		local c = u32(s, pos)
		pos = pos + 4
		if c > MAX_COUNT then
			error("BLV " .. what .. " count out of range: " .. c)
		end
		return c
	end

	local vcount = take_count("vertex")
	local vbase = pos -- vertices: 6 bytes each (i2 X, Y, Z)
	pos = pos + vcount * 6

	local fcount = take_count("facet")
	pos = pos + fcount * REC.facet + facetDataSize + fcount * 10

	local fdcount = take_count("facet data")
	pos = pos + fdcount * 0x24 + fdcount * 10

	local rcount = take_count("room")
	pos = pos + rcount * REC.room + roomDataSize + roomLightDataSize

	take_count("door") -- count only, no data in blv

	local scount = take_count("sprite")
	pos = pos + scount * REC.sprite + scount * 32

	local lcount = take_count("light")
	pos = pos + lcount * REC.light

	local bspcount = take_count("bsp")
	pos = pos + bspcount * 8

	local spawncount = take_count("spawn")
	pos = pos + spawncount * REC.spawn

	local ocount = take_count("outline")
	if pos + ocount * 12 - 1 ~= n then
		error(string.format("BLV section walk mismatch (outlines end at %d, file size %d)",
			pos + ocount * 12 - 1, n))
	end
	if ocount == 0 then
		error("BLV has no outlines")
	end

	local lines = {}
	local min_x, max_x = math.huge, -math.huge
	local min_y, max_y = math.huge, -math.huge
	for i = 0, ocount - 1 do
		local o = pos + i * 12
		local v1 = u16(s, o)
		local v2 = u16(s, o + 2)
		if v1 >= vcount or v2 >= vcount then
			error("BLV outline references vertex out of range")
		end
		local a, b = vbase + v1 * 6, vbase + v2 * 6
		local x1, y1 = i16(s, a), i16(s, a + 2)
		local x2, y2 = i16(s, b), i16(s, b + 2)
		lines[#lines + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
		min_x = math.min(min_x, x1, x2)
		max_x = math.max(max_x, x1, x2)
		min_y = math.min(min_y, y1, y2)
		max_y = math.max(max_y, y1, y2)
	end

	return {
		min_x = min_x,
		min_y = min_y,
		max_x = max_x,
		max_y = max_y,
		lines = lines,
	}
end

-- For uncompressed (no 'mvii' header) entries the size must come from a lod
-- directory. The patch's recently-loaded-files records (which point to the
-- custom lod that served the file) are checked FIRST: custom archives can
-- share directory offsets with the base lod (they are often rebuilt copies),
-- so a base-lod offset match alone could pick the wrong copy's size.
local function find_entry_size(name, entry_start)
	local size

	local function scan_lod(lod)
		local files = lod.Files
		for i = 0, files.count - 1 do
			local f = files[i]
			if f.Name:lower() == name and lod.FilesOffset + f.Offset == entry_start then
				size = f.Size
				return true
			end
		end
	end

	pcall(function()
		local recs = Game.CustomLods.Records
		for i = 0, 255 do
			local r = recs[i]
			if r.LodPtr ~= 0 and r.Name:lower() == name then
				if scan_lod(structs.Lod:new(r.LodPtr)) then
					return
				end
			end
		end
	end)
	if size then
		return size
	end

	pcall(scan_lod, Game.GamesLod)
	return size
end

-- exposed for offline testing only
M._parse_blv = parse_blv

-- Read outlines of the currently loaded indoor map straight from game memory.
-- Returns the same structure as read_map, or nil.
function M.read_current_map()
	local ok, result = pcall(function()
		if Map.IsOutdoor() or Map.Outlines.Items.count == 0 then
			return nil
		end
		local lines = {}
		local min_x, max_x = math.huge, -math.huge
		local min_y, max_y = math.huge, -math.huge
		for _, edge in Map.Outlines.Items do
			local a = Map.Vertexes[edge.Vertex1]
			local b = Map.Vertexes[edge.Vertex2]
			local x1, y1, x2, y2 = a.X, a.Y, b.X, b.Y
			lines[#lines + 1] = { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
			min_x = math.min(min_x, x1, x2)
			max_x = math.max(max_x, x1, x2)
			min_y = math.min(min_y, y1, y2)
			max_y = math.max(max_y, y1, y2)
		end
		if #lines == 0 then
			return nil
		end
		return {
			min_x = min_x,
			min_y = min_y,
			max_x = max_x,
			max_y = max_y,
			lines = lines,
		}
	end)
	return ok and result or nil
end

-- Read outlines of any indoor map by its blv file name (with or without
-- extension), e.g. "d07.blv" or "d07". Returns data table, or nil, err.
function M.read_map(map_filename)
	local name = map_filename:lower()
	if not name:match("%.blv$") then
		name = name .. ".blv"
	end

	local stream = Game.GamesLod:FindFile(name, true)
	if not stream or stream == 0 then
		return nil, "map file not found in games lod archives: " .. name
	end
	local entry_start = Game.FileTell(stream)

	local head = freadstr(stream, 16)
	if not head then
		return nil, "failed to read entry header of " .. name
	end

	local data
	if head:sub(5, 8) == "mvii" then
		-- compressed entry: sizes are in the header itself
		local comp = u32(head, 9)
		local uncomp = u32(head, 13)
		if comp <= 0 or comp > MAX_SIZE or uncomp < 0x8C or uncomp > MAX_SIZE then
			return nil, string.format("implausible compressed entry sizes in %s (%d -> %d)", name, comp, uncomp)
		end
		local cdata = freadstr(stream, comp)
		if not cdata then
			return nil, "short read of compressed data of " .. name
		end
		local ok, out = pcall(zzlib.inflate, cdata)
		if not ok then
			return nil, "decompression of " .. name .. " failed: " .. tostring(out)
		end
		if #out ~= uncomp then
			return nil, string.format("decompressed size mismatch for %s (%d, expected %d)", name, #out, uncomp)
		end
		data = out
	else
		-- raw entry: size must come from a lod directory
		local size = find_entry_size(name, entry_start)
		if not size or size <= 0 or size > MAX_SIZE then
			return nil, "cannot determine size of uncompressed entry " .. name
		end
		Game.FileSeek(stream, entry_start, 0)
		data = freadstr(stream, size)
		if not data then
			return nil, "short read of " .. name
		end
	end

	local ok, result = pcall(parse_blv, data)
	if not ok then
		return nil, name .. ": " .. tostring(result)
	end
	return result
end

return M
