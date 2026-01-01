-- police_road_cone.lua — demo: police zombie on road spawns a cone once per tile.
--[[ Usage in PZ console:
handle = require("examples/police_road_cone").start()
-- later when you want to stop:
handle.stop()
]]

local PoliceRoadCone = {}

local CONE_SPRITE = "street_decoration_01_26"
local CONE_DAMAGED = "damaged_objects_01_26"

local leases
local promise

function PoliceRoadCone.start(opts)
	opts = opts or {}
	PoliceRoadCone.stop()

	local PromiseKeeper = require("PromiseKeeper")
	local WorldObserver = require("WorldObserver")

	local namespace = opts.namespace or "DREAM.PoliceRoadCone"
	local pk = PromiseKeeper.namespace(namespace)
	local wo = WorldObserver.namespace(namespace)

	pk.situations.searchIn(WorldObserver)

	leases = {
		zombies = wo.factInterest:declare("zombies", {
			type = "zombies",
			scope = "allLoaded",
			radius = { desired = 30, tolerable = 20 },
			zRange = { desired = 1, tolerable = 2 },
			staleness = { desired = 0.5, tolerable = 1 },
			cooldown = { desired = 0.5, tolerable = 1 },
			--highlight = true,
		}),
		squares = wo.factInterest:declare("squares", {
			type = "squares",
			scope = "near",
			radius = { desired = 20, tolerable = 5 },
			staleness = { desired = 30, tolerable = 50 },
			cooldown = { desired = 40, tolerable = 50 },
			--highlight = true,
		}),
	}

	local zombies = WorldObserver.observations:zombies():hasOutfit("Police%")
	local squares = WorldObserver.observations:squares():isRoad()

	wo.situations.define("policeOnRoad", function()
		return WorldObserver.observations
			:derive({ zombie = zombies, square = squares }, function(lqr)
				return lqr.zombie
					:innerJoin(lqr.square)
					:using({ zombie = "tileLocation", square = "tileLocation" })
					:joinWindow({ time = 100 * 1000 })
			end)
			:withOccurrenceKey({ "square" })
	end)

	pk.actions.define("spawnRoadCone", function(subject)
		local squareRecord = subject.square
		local square = WorldObserver.helpers.square.record.getIsoGridSquare(squareRecord)

		-- check if there is such a object already
		local objects = square:getObjects()
		local count = objects:size()
		for i = 0, count - 1 do
			local obj = objects:get(i)
			local spriteName = obj:getSprite():getName()
			if spriteName == CONE_SPRITE or spriteName == CONE_DAMAGED then
				return -- yup there is a cone, no need to spawn it
			end
		end

		-- spawn the cone
		local obj = IsoObject.new(getWorld():getCell(), square, getSprite(CONE_SPRITE))
		obj:setName("console_spawned_object")
		square:AddTileObject(obj)
	end)

	promise = pk.promise({
		promiseId = "WHEN policeOnRoad THEN spawnRoadCone forever sometimes", --best practice but use any key you like
		situationKey = "policeOnRoad", -- when this
		actionId = "spawnRoadCone", -- do that
		policy = { maxRuns = -1, chance = 0.25 },
	})

	return {
		stop = PoliceRoadCone.stop,
		promise = promise,
	}
end

function PoliceRoadCone.stop()
	if promise and promise.forget then
		promise.forget()
	end
	promise = nil

	if leases then
		for _, lease in pairs(leases) do
			if lease and lease.stop then
				lease:stop()
			end
		end
		leases = nil
	end
end

return PoliceRoadCone
