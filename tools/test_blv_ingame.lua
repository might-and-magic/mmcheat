-- In-game test for runtime BLV indoor-map extraction (MMCheat research), v2.
-- Tests the actual production module MMCheat/util/image/blvreader.lua
-- (FindFile + FileRead + pure-Lua zlib decompression; the game's generic LOD
-- loader is NOT used - it fatally crashes the game on games lods).
--
-- HOW TO USE:
--   1. Copy this file into Scripts/Global/
--   2. Start the game, load a save (any map), press Ctrl+F9
--   3. Wait for the "BLV test done" status message (may take a minute)
--   4. Results: mmcheat_blv_test.log and mmcheat_blv_dump_*.txt in game folder
--   5. Delete this file from Scripts/Global/ afterwards

local blvreader = require("MMCheat/util/image/blvreader")

-- maps whose outline lines get dumped to a file for offline byte-comparison
local DUMP_MAPS = {
	["d07.blv"] = true,
	["6d03.blv"] = true,
	["7d05.blv"] = true,
	["d05.blv"] = true,
	["eleme.blv"] = true,
}

local logf

local function log(fmt, ...)
	local s = select("#", ...) > 0 and string.format(fmt, ...) or fmt
	logf:write(s, "\n")
end

-- Which archive did FindFile resolve a file to? (diagnostic)
-- The patch's recently-loaded-files ring maps file names to the custom lod
-- that serves them; a file served by the base lod has no ring record.
local function serving_archive(name, tellpos)
	local label
	pcall(function()
		-- ring records first: custom archives can share directory offsets with
		-- the base lod, so a base offset match alone would mislabel those
		local recs = Game.CustomLods.Records
		for i = 0, 255 do
			local r = recs[i]
			if r.LodPtr ~= 0 and r.Name:lower() == name then
				label = structs.Lod:new(r.LodPtr).FileName
				return
			end
		end
		local files = Game.GamesLod.Files
		for i = 0, files.count - 1 do
			local f = files[i]
			if f.Name:lower() == name and Game.GamesLod.FilesOffset + f.Offset == tellpos then
				label = "(base) " .. Game.GamesLod.FileName
				return
			end
		end
	end)
	return label or "(unknown)"
end

local function test_map(fn)
	local name = fn:lower()

	-- diagnostic: resolution info
	local stream = Game.GamesLod:FindFile(name, true)
	if stream == 0 then
		log("== %-12s FindFile: NOT FOUND", fn)
		return
	end
	local tellpos = Game.FileTell(stream)

	-- production path
	local t0 = os.clock()
	local map, err = blvreader.read_map(name)
	local ms = (os.clock() - t0) * 1000

	if not map then
		log("== %-12s FAIL (%.0f ms) tell=%-9d from %s", fn, ms, tellpos, serving_archive(name, tellpos))
		log("   error: %s", tostring(err))
		return
	end

	log("== %-12s OK   (%.0f ms) outlines=%-5d bounds=(%d,%d,%d,%d) from %s",
		fn, ms, #map.lines, map.min_x, map.min_y, map.max_x, map.max_y,
		serving_archive(name, tellpos))

	-- compare with in-memory outlines when this is the current map
	local current = Map.Name:lower():match("^(.*)%.[^%.]+$")
	if current and current .. ".blv" == name then
		local memmap = blvreader.read_current_map()
		if memmap then
			local ndiff = 0
			local nmax = math.max(#memmap.lines, #map.lines)
			for i = 1, nmax do
				local a, b = memmap.lines[i], map.lines[i]
				if not a or not b or a.x1 ~= b.x1 or a.y1 ~= b.y1 or a.x2 ~= b.x2 or a.y2 ~= b.y2 then
					ndiff = ndiff + 1
				end
			end
			log("   CURRENT MAP CHECK: memory=%d parsed=%d differing-lines=%d (door movement expected)",
				#memmap.lines, #map.lines, ndiff)
		end
	end

	if DUMP_MAPS[name] then
		local base = name:match("^(.*)%.blv$") or name
		local df = io.open("mmcheat_blv_dump_" .. base .. ".txt", "w")
		if df then
			for _, l in ipairs(map.lines) do
				df:write(l.x1, ",", l.y1, ",", l.x2, ",", l.y2, "\n")
			end
			df:close()
			log("   dumped %d lines to mmcheat_blv_dump_%s.txt", #map.lines, base)
		end
	end
end

local function run_test()
	logf = io.open("mmcheat_blv_test.log", "w")
	if not logf then
		Game.ShowStatusText("cannot open mmcheat_blv_test.log")
		return
	end
	logf:setvbuf("no") -- flush every write: nothing gets lost if the game dies

	log("MMCheat BLV runtime test v2 (blvreader, no native loader)")
	log("Game.Version=%d  Map.Name=%s", Game.Version, Map.Name)
	log("GamesLod: FileName=%s FilesOffset=%d Files.count=%d",
		Game.GamesLod.FileName, Game.GamesLod.FilesOffset, Game.GamesLod.Files.count)
	log("")

	local tested, okc, failc = 0, 0, 0
	local total_t0 = os.clock()
	for i = 1, Game.MapStats.Count - 1 do
		local ok, err = pcall(function()
			local fn = Game.MapStats[i].FileName
			if fn:lower():match("%.blv$") then
				tested = tested + 1
				test_map(fn)
			end
		end)
		if not ok then
			log("== MapStats[%d]: SCRIPT ERROR %s", i, tostring(err))
			failc = failc + 1
		end
	end
	log("")
	log("done: %d indoor maps tested in %.1f s", tested, os.clock() - total_t0)
	logf:close()
	Game.ShowStatusText("BLV test done: " .. tested .. " maps, see mmcheat_blv_test.log")
end

---@diagnostic disable-next-line: duplicate-set-field
function events.KeyDown(t)
	if t.Key == const.Keys.F9 and Keys.IsPressed(const.Keys.CTRL) then
		local ok, err = pcall(run_test)
		if not ok then
			if logf then
				pcall(function()
					logf:write("FATAL: ", tostring(err), "\n")
					logf:close()
				end)
			end
			Game.ShowStatusText("BLV test error: " .. tostring(err))
		end
	end
end
