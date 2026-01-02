-- examples/prefabs/marriage.lua -- SceneBuilder prefab for a church marriage scene.

local Marriage = {}

---@param roomDef any
function Marriage.makeForRoomDef(roomDef)
	local Scene = require("SceneBuilder/core")

	-- SceneBuilder is a declarative "builder" API: describe what to spawn, then call `:spawn()`.
	Scene:begin(roomDef, { tag = "marriage" })
		:zombies(function(z)
			-- `where(...)` picks a spawn strategy; fallbacks keep the demo robust across room layouts.
			z:count(1):outfit("WeddingDress"):femaleChance(100):where("centroidFreeOrMidair", { fallback = { "any" } })
		end)
		:zombies(function(z)
			z:count(1):outfit("Groom"):femaleChance(0):where("centroidFreeOrMidair", { fallback = { "any" } })
		end)
		:zombies(function(z)
			z:count(1):outfit("Priest"):femaleChance(0):where("centroidFreeOrMidair", { fallback = { "any" } })
		end)
		:spawn()
end

return Marriage
