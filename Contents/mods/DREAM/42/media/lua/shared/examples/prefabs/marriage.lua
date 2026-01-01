-- examples/prefabs/marriage.lua -- SceneBuilder prefab for a church marriage scene.

local Marriage = {}

---@param roomDef any
function Marriage.makeForRoomDef(roomDef)
	local Scene = require("SceneBuilder/core")

	Scene:begin(roomDef, { tag = "marriage" })
		:zombies(function(z)
			z
				:count(1)
				:outfit("WeddingDress")
				:femaleChance(100)
				:where("freeOrMidair", { fallback = { "any" } })
		end)
		:zombies(function(z)
			z
				:count(1)
				:outfit("Groom")
				:femaleChance(0)
				:where("freeOrMidair", { fallback = { "any" } })
		end)
		:zombies(function(z)
			z
				:count(1)
				:outfit("Priest")
				:femaleChance(0)
				:where("freeOrMidair", { fallback = { "any" } })
		end)
		:zombies(function(z)
			z
				:count(6)
				:femaleChance(50)
				:where("freeOrMidair", { fallback = { "any" } })
		end)
		:spawn()
end

return Marriage
