-- police_road_cone.lua — demo: police zombie on road spawns a cone once per tile.
--[[ Usage in PZ console:
require("DREAMBase/log").setLevel("info")
handle = require("examples/police_road_cone").start()
-- later when you want to stop:
handle.stop()
]]

local Log = require("DREAMBase/log").withTag("DREAM.EXAMPLE.police_road_cone")

local PoliceRoadCone = {}

local CONE_SPRITE = "street_decoration_01_26"
local CONE_DAMAGED = "damaged_objects_01_26"

local leases = nil
local debugSubs = nil
local promise = nil

function PoliceRoadCone.start(opts)
	opts = opts or {}
	local debugEnabled = opts.debug == true
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
			radius = { desired = 10, tolerable = 30 },
			zRange = { desired = 1, tolerable = 2 },
			staleness = { desired = 0.2, tolerable = 1 },
			cooldown = { desired = 0.2, tolerable = 1 },
			highlight = true,
		}),
		squares = wo.factInterest:declare("squares", {
			type = "squares",
			scope = "near",
			radius = { desired = 10, tolerable = 5 },
			staleness = { desired = 5, tolerable = 10 },
			cooldown = { desired = 10, tolerable = 20 },
			highlight = true,
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
					:joinWindow({ time = 40 * 1000 })
			end)
			:withOccurrenceKey({ "square" })
	end)

	if debugEnabled then
		debugSubs = {
			zombies = zombies:distinct("zombie", 1):subscribe(function(observation)
				local z = observation.zombie
				Log:info("[debug] zombie outfit=%s tile=%s", tostring(z.outfitName), tostring(z.tileLocation))
			end),
			squares = squares:distinct("square", 1):subscribe(function(observation)
				local s = observation.square
				Log:info("[debug] square floorMaterial=%s tile=%s", tostring(s.floorMaterial), tostring(s.tileLocation))
			end),
		}
	end

	if opts.debugRaw == true then
		debugSubs = debugSubs or {}
		debugSubs.rawZombies = WorldObserver.observations
			:zombies()
			:distinct("zombie", 1)
			:subscribe(function(observation)
				local z = observation.zombie
				Log:info("[debug-raw] zombie outfit=%s tile=%s", tostring(z.outfitName), tostring(z.tileLocation))
			end)
		debugSubs.rawSquares = WorldObserver.observations
			:squares()
			:distinct("square", 1)
			:subscribe(function(observation)
				local s = observation.square
				Log:info(
					"[debug-raw] square floorMaterial=%s tile=%s",
					tostring(s.floorMaterial),
					tostring(s.tileLocation)
				)
			end)
	end

	pk.actions.define("spawnRoadCone", function(subject, _args, promiseCtx)
		local squareRecord = subject.square
		local square = WorldObserver.helpers.square.record.getIsoGridSquare(squareRecord)

		local objects = square:getObjects()
		local count = objects:size()
		for i = 0, count - 1 do
			local obj = objects:get(i)
			local spriteName = obj:getSprite():getName()
			if spriteName == CONE_SPRITE or spriteName == CONE_DAMAGED then
				return
			end
		end

		local cell = getWorld():getCell()
		local sprite = getSprite(CONE_SPRITE)
		local obj = IsoObject.new(cell, square, sprite)
		obj:setName("console_spawned_object")
		square:AddTileObject(obj)
		if debugEnabled then
			Log:info(
				"spawned cone occurranceKey=%s tile=%s",
				tostring(promiseCtx.occurranceKey),
				tostring(squareRecord.tileLocation)
			)
		end
	end)

	promise = pk.promise({
		promiseId = "spawnRoadCone",
		situationKey = "policeOnRoad",
		actionId = "spawnRoadCone",
		policy = { maxRuns = -1, chance = 0.5 },
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
	if debugSubs then
		if debugSubs.zombies and debugSubs.zombies.unsubscribe then
			debugSubs.zombies:unsubscribe()
		end
		if debugSubs.squares and debugSubs.squares.unsubscribe then
			debugSubs.squares:unsubscribe()
		end
		if debugSubs.rawZombies and debugSubs.rawZombies.unsubscribe then
			debugSubs.rawZombies:unsubscribe()
		end
		if debugSubs.rawSquares and debugSubs.rawSquares.unsubscribe then
			debugSubs.rawSquares:unsubscribe()
		end
		debugSubs = nil
	end

	for _, lease in pairs(leases or {}) do
		if lease and lease.stop then
			lease:stop()
		end
	end
	leases = nil
end

return PoliceRoadCone
