-- police_road_cone.lua — demo: police zombie on road spawns a cone once per tile.
--[[ Usage in PZ console:
require("DREAMBase/log").setLevel("info")
handle = require("examples/police_road_cone").start()
-- later when you want to stop:
handle:stop()
]]

local Log = require("DREAMBase/log").withTag("DREAM.PoliceRoadCone")
local SquareHelpers = require("WorldObserver/helpers/square")

local PoliceRoadCone = {}

local CONE_SPRITE = "street_decoration_01_26"
local CONE_DAMAGED = "damaged_objects_01_26"
local HIGHLIGHT_DURATION_MS = 2000

local leases
local promise

local function squareHasCone(isoSquare)
	-- Tiny idempotence helper: we don't want to place multiple cones on the same tile.
	local objects = isoSquare:getObjects()
	local count = objects:size()
	for i = 0, count - 1 do
		local obj = objects:get(i)
		local sprite = obj and obj.getSprite and obj:getSprite() or nil
		local spriteName = sprite and sprite.getName and sprite:getName() or nil
		if spriteName == CONE_SPRITE or spriteName == CONE_DAMAGED then
			return true
		end
	end
	return false
end

function PoliceRoadCone.start()
	PoliceRoadCone.stop()
	Log:info("start")

	local PromiseKeeper = require("PromiseKeeper")
	local WorldObserver = require("WorldObserver")

	local namespace = "DREAM.PoliceRoadCone"
	local pk = PromiseKeeper.namespace(namespace)
	local wo = WorldObserver.namespace(namespace)

	-- Bridge point: PromiseKeeper consumes situations defined by other modules (WorldObserver here).
	pk.situations.searchIn(WorldObserver)

	-- ## Fact Layer ##
	-- Interests are WorldObserver "inputs": they decide what facts are produced and how fresh they are.
	leases = {
		zombies = wo.factInterest:declare("zombies", {
			type = "zombies",
			scope = "allLoaded",
			radius = { desired = 30 },
			zRange = { desired = 1 },
			staleness = { desired = 1 },
			cooldown = { desired = 1 },
		}),
		squares = wo.factInterest:declare("squares", {
			type = "squares",
			scope = "near",
			radius = { desired = 20 },
			staleness = { desired = 30 },
			cooldown = { desired = 40 },
		}),
	}

	-- ## Situation Layer ##
	-- Situations are streams of "candidates" that PromiseKeeper can turn into persisted occurrences.
	wo.situations.define("policeOnRoad", function()
		local policeZeds = wo.observations:zombies():hasOutfit("Police%")
		local roadSquares = wo.observations:squares():hasFloorMaterial("Road%")
		return wo.observations
			:derive({ zombie = policeZeds, square = roadSquares }, function(lqr)
				return lqr.zombie
					:innerJoin(lqr.square)
					-- Joining on stable record keys keeps the query engine-safe.
					:using({ zombie = "tileLocation", square = "tileLocation" })
					:joinWindow({ time = 100 * 1000 })
			end)
			-- Occurrence keys are persistence keys: "once per square" is driven by the key strategy.
			:withOccurrenceKey({ "square" })
	end)

	-- ## Action Layer ##
	-- Actions should be idempotent (they may run again after reloads or on repeated observations).
	pk.actions.define("spawnRoadCone", function(subject)
		local square = subject and subject.square or nil
		local isoSquare = SquareHelpers.record.getIsoGridSquare(square)
		if isoSquare == nil then
			return
		end

		if squareHasCone(isoSquare) then
			return
		end

		local obj = IsoObject.new(getWorld():getCell(), isoSquare, getSprite(CONE_SPRITE))
		obj:setName("DREAM.PoliceRoadCone")
		isoSquare:AddTileObject(obj)

		SquareHelpers.highlight(
			square,
			HIGHLIGHT_DURATION_MS,
			{ color = { 1, 0.2, 0.2 }, alpha = 0.9, blink = false }
		)
	end)

	promise = pk.promise({
		promiseId = "WHEN policeOnRoad THEN spawnRoadCone",
		situationKey = "policeOnRoad",
		actionId = "spawnRoadCone",
		-- Policy is "how often": chance is deterministic per (namespace, promiseId, occurranceKey).
		policy = { maxRuns = -1, chance = 0.25 },
	})

	-- Housekeeping: return a small "handle" so callers can stop the example and inspect its internals.
	return {
		stop = PoliceRoadCone.stop,
		promise = promise,
	}
end

function PoliceRoadCone.stop()
	-- Housekeeping: cleanly tear down everything created by `start()` so we can restart without
	-- duplicate listeners, leases, or persisted promises continuing to run in the background.
	if promise and promise.forget then
		promise.forget()
	end
	-- Make the shutdown idempotent: once stopped, repeated calls do nothing.
	promise = nil

	if leases then
		for _, lease in pairs(leases) do
			if lease and lease.stop then
				lease:stop()
			end
		end
	end
	leases = nil

	Log:info("stop")
end

return PoliceRoadCone
