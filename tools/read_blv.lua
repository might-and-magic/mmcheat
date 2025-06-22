-- Modified and fixed based on `Scripts/Global/Convert Blv.lua`

local mmver = Game.Version

local function mmv(...)
	return (select(mmver - 5, ...))
end

local function StructInfo(a)
	local fields = (getmetatable(a) or {}).members
	local kind = fields and structs.name(a)
	---@diagnostic disable-next-line: undefined-field
	if not kind and debug.upvalues(getmetatable(a).__newindex).SetLen then
		return
	elseif not kind then
		fields = {}
		local ok = pcall(function()
			for i in a do
				fields[i] = true
			end
		end)
		if not ok and a.Male ~= nil and a.Female ~= nil then -- MapMonster.Prefers is the only union of interest
			return const.MonsterPref
		elseif not ok then
			return
		end
	end
	return fields, kind
end

local function CleanupStruct(a, t)
	for k in pairs(StructInfo(a) or {}) do
		if type(t[k]) == 'table' then
			CleanupStruct(a[k], t[k])
		elseif a[k] == t[k] then
			t[k] = nil
		end
	end
end

local function initItem(a, num)
	mem.fill(a)
	a.Number = num
	if a.InitSpecial then
		a:InitSpecial()
	elseif mmver > 6 then
		mem.call(mmv(nil, 0x456D51, 0x4545E8), 1, Game.ItemsTxt["?ptr"] - 4, a)
	end
	a.Number = 0
end

local SkipFields = {
	MapSprite = { Bits = true, DecName = true },
	MapMonster = { Bits = true, PrefClass = true },
	MapRoom = {},
}
local PostRead = {
	MapMonster = function(a, t)
		do
			Map.Monsters.Count = 0
			local b = SummonMonster(t.Id, 0, 0, 0, true)
			b.GuardRadius = 0
			CleanupStruct(b, t)
			t.Id = b.Id
			if mmver == 6 or (t.NPC_ID or 0) < 0 or (t.NPC_ID or 0) >= 5000 then
				t.NPC_ID = nil
			end
		end
	end,
	MapObject = function(a, t)
		do
			a, t = a.Item, t.Item
			local s = mem.string(a['?ptr'], a['?size'], true)
			initItem(a, t.Number)
			CleanupStruct(a, t)
			mem.copy(a, s)
		end
	end,
	MapFacet = function(a, t)
		if mmver == 6 and t.Untouchable and not t.Invisible and (t.NormalZ or 0) ~= 0 then
			t.UntouchableMM6 = true
			t.Untouchable = nil
		end
	end,
	FacetData = function(a, t) t.Id = mmver ~= 6 and t.Id or t.FacetIndex end,
	MapLight = function(a, t, idx) t.Id = t.Id or idx end,
}
local PreWrite = {
	MapMonster = function(a, t)
		do
			Map.Monsters.Count = 0
			local b = SummonMonster(t.Id, 0, 0, 0, true)
			b.GuardRadius = 0
			mem.copy(a['?ptr'], b['?ptr'], a['?size'])
		end
	end,
	MapObject = function(a, t)
		do
			initItem(a.Item, t.Item.Number)
		end
	end,
	MapLight = function(a, t)
		if mmver ~= 6 then
			a.Type = 5
			a.Brightness = 31
		end
	end,
}
local PostWrite = {
	MapObject = function(a, t)
		do
			-- a.Type = Game.ItemsTxt[a.Item.Number].SpriteIndex
			a.TypeIndex = Game.ObjListBin.Find(a.Type)
		end
	end,
	MapFacet = function(a, t)
		do
			a.NormalFX = t.NormalFX or a.NormalX / 0x10000
			a.NormalFY = t.NormalFY or a.NormalY / 0x10000
			a.NormalFZ = t.NormalFZ or a.NormalZ / 0x10000
			a.NormalFDistance = t.NormalFDistance or a.NormalDistance / 0x10000
			if mmver == 6 then
				a.Untouchable = t.Untouchable or t.UntouchableMM6
			end
			t.Bits = a.Bits -- for dlv
		end
	end,
	MapSprite = function(a, t) t.Bits = a.Bits end, -- for dlv
}

local invoke = function(f, ...)
	if f then
		f(...)
	end
end

local function IsResizeable(t)
	local f = getmetatable(t).__newindex
	if f then
		---@diagnostic disable-next-line: undefined-field
		local i, v = debug.findupvalue(f, 'SetLen')
		return v ~= nil
	end
end

local function CopyStruct(a, t, name)
	local fields, kind = StructInfo(a)
	-- print('fields:', fields)
	if not fields then
		return true
	end
	t = tget(t, name)

	local skip = SkipFields[kind] or { Bits = true }
	for k in pairs(fields) do
		if k == '' or skip[k] then
			-- skip
		elseif type(a[k]) == 'table' then
			-- if kind == 'MapChest' then
			-- 	print(debug.upvalues(getmetatable(a[k]).__newindex).SetLen)
			-- end
			if CopyStruct(a[k], t, k) and IsResizeable(a[k]) then
				t['#' .. k] = a[k].count
			end
		else
			t[k] = a[k]
		end
	end
	invoke(PostRead[kind], a, t, name)
end

local function rd(state, fname)
	local blv = io.open(fname, 'rb')

	if not blv then
		print("Failed to open file: " .. tostring(fname))
		return
	end

	local buf = mem.malloc(10000)
	local target, file = state, blv

	local function Each(t, f, hdrName)
		local off = file:seek()
		for i = 0, #t do
			target = t[i]
			if target then
				f(target)
			end
		end
		target = state
		if hdrName then
			state.Header[hdrName] = file:seek() - off
		end
	end

	local function zero(n)
		file:seek(nil, n)
	end

	local function str(name, n)
		target[name] = file:read(n):match '[^%z]*'
	end

	local function num(name, n)
		local s = file:read(n or 4)
		local v = 0
		for i = #s, 1, -1 do
			v = v * 256 + s:byte(i)
		end
		local v1 = 256 ^ (n or 4)
		target[name] = (v * 2 < v1 and v or v - v1)
	end

	local function stru(name, kind)
		local a = structs[kind]:new(buf)
		-- print(name, kind, 'off', file:seek(), 'size', a['?size'])
		local s = file:read(a['?size'])
		mem.copy(buf, s)
		CopyStruct(a, target, name)
	end

	local function narr(f, name, n, ...)
		-- print('off', file:seek(), 'name', name, 'count', n)
		local old = target
		target = tget(target, name)
		for i = 0, n - 1 do
			f(i, ...)
		end
		target = old
	end
	local function arr(f, name, ...)
		num('#' .. name)
		-- print('vcount', target['#'..name], 'newoff', file:seek())
		narr(f, name, target['#' .. name], ...)
	end
	local function marr(add, f, name, ...)
		narr(f, name, target['#' .. name] + add, ...)
	end

	local astru = function(...) return arr(stru, ...) end
	local mnum = function(...) return marr(0, num, ...) end
	local mnum1 = function(...) return marr(1, num, ...) end

	-- Blv
	stru('Header', 'BlvHeader')
	astru('Vertexes', 'MapVertex')

	astru('Facets', 'MapFacet')
	Each(state.Facets, function(a)
		do
			mnum1('VertexIds', 2)
			mnum1('XInterceptDisplacement', 2)
			mnum1('YInterceptDisplacement', 2)
			mnum1('ZInterceptDisplacement', 2)
			mnum1('UList', 2)
			mnum1('VList', 2)
		end
	end, 'FacetDataSize')
	-- error'Hello!'
	Each(state.Facets, function() str('Bitmap', 10) end)

	astru('FacetData', 'FacetData')
	Each(state.FacetData, function(a) zero(10) end)
	astru('Rooms', 'MapRoom')
	Each(state.Rooms, function()
		do
			mnum('Floors', 2)
			mnum('Walls', 2)
			mnum('Ceils', 2)
			mnum('Fluids', 2)
			mnum('Portals', 2)
			mnum('DrawFacets', 2)
			mnum('Cogs', 2)
			mnum('Sprites', 2)
			mnum('Markers', 2)
		end
	end, 'RoomDataSize')
	Each(state.Rooms, function() mnum('Lights', 2) end, 'RoomLightDataSize')

	num('DoorsCount')
	astru('Sprites', 'MapSprite')
	Each(state.Sprites, function() str('DecName', 32) end)
	astru('Lights', 'MapLight')
	astru('BSPNodes', 'BSPNode')
	astru('Spawns', 'SpawnPoint')
	astru('Outlines', 'MapOutline')

	mem.free(buf)
	blv:close()
end

local function read_blv(fname)
	local state = { Header = {} }
	rd(state, fname)
	return state
end

print(dump(read_blv("tk02i.blv")))

-- return read_blv

local fileStream = Game.GamesLod:FindFile("tk02i.blv", true)
print(fileStream)

-- Game.FileTell(fileStream)

-- function readLodFile(lod, filename)
-- 	local file = lod:FindFile(filename, true)
-- 	if not file then
-- 		return nil, "File not found"
-- 	end

-- 	local offset = 6067208

-- 	local size = 29786

-- 	Game.FileSeek(file, offset, 0)
-- 	local AA = Game.FileTell(file)
-- 	print(AA)

-- 	local buf = mem.malloc(size)
-- 	Game.FileRead(buf, size, 1, file)       -- Read into buffer

-- 	local result = mem.string(buf, size, true)
-- 	mem.free(buf)
-- 	return result
-- end
-- local data, err = readLodFile(Game.GamesLod, "d49.blv")
-- if data then
--     print("File size:", #data)
--     print("First 16 bytes (hex): ")
--     for i = 1, 16 do
--         print(string.format("%02X ", string.byte(data, i)))
--     end
--     print()  -- newline
-- else
--     print("Error:", err)
-- end
