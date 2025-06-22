-- MMCheat: Might and Magic 678 Merge and GrayFace Might and Magic 6/7/8 Cheat Suite & Helper Tool
-- CTRL + Backspace in the game to open MMCheat
-- https://github.com/might-and-magic/mmcheat
-- By Tom Chen. MIT License
local main = require("MMCheat/ui/main")

---@diagnostic disable-next-line: duplicate-set-field
function events.AfterLoadMap()
	---@diagnostic disable-next-line: duplicate-set-field
	function events.KeyDown(t)
		if t.Key == const.Keys.BACKSPACE and Keys.IsPressed(const.Keys.CTRL) then
			-- `main()` must wait util Game initialized at earliest
			main()
		end
	end
end
