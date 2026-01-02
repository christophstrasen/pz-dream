-- hedge_trample.lua - demo: remove hedge tiles when enough zombies trample the same square.
--[[ Usage in PZ console:
require("DREAMBase/log").setLevel("info")
handle = require("examples/hedge_trample").start()
handle:stop()
]]

local Log = require("DREAMBase/log").withTag("DREAM.HedgeTrample")
local SquareHelpers = require("WorldObserver/helpers/square")

local HedgeTrample = {}

local leases
local subscription

function HedgeTrample.start()
	HedgeTrample.stop()
	Log:info("start")

	local WorldObserver = require("WorldObserver")
	local namespace = "DREAM.HedgeTrample"
	local wo = WorldObserver.namespace(namespace)

	-- ## Fact Layer ##
	-- Interests are WorldObserver "inputs": they decide what facts get produced and at what cadence.
	leases = {
		zombies = wo.factInterest:declare("zombies", {
			type = "zombies",
			scope = "allLoaded",
			radius = { desired = 25 },
			zRange = { desired = 1 },
			staleness = { desired = 1 },
			cooldown = { desired = 1 },
			highlight = { 1, 0.2, 0.2 },
		}),
		sprites = wo.factInterest:declare("sprites", {
			type = "sprites",
			scope = "near",
			radius = { desired = 25 },
			staleness = { desired = 10 },
			cooldown = { desired = 20 },
			highlight = { 0.2, 0.2, 0.8 },
			-- Trailing `%` means "prefix wildcard".
			spriteNames = { "vegetation_ornamental_01_%" },
		}),
	}

	-- ## Situation Layer ##
	-- Join Observations: zombie with hedge sprite by tile, then aggregate "unique zombies per tile".
	subscription = wo
		.observations
		:derive({
			zombie = wo.observations:zombies(),
			sprite = wo.observations:sprites(),
		}, function(LQR) -- building derived observations via LQR
			return LQR.zombie
				:innerJoin(LQR.sprite)
				:using({ zombie = "tileLocation", sprite = "tileLocation" })
				:joinWindow({
					time = 50 * 1000, -- ms. If this is smaller than fact staleness/cooldown, joins may become flaky.
				})
				:groupByEnrich("tileLocation_grouped", function(row)
					return row.zombie.tileLocation
				end)
				:groupWindow({
					time = 10 * 1000, -- ms. Sliding window for aggregates, relative to the time in the `field`.
					field = "zombie.sourceTime",
				})
				:aggregates({
					count = {
						{
							path = "zombie.zombieId", -- `path` chooses which field exists for "count" bookkeeping.
							distinctFn = function(row) -- Same Zed can be observed multiple times. We have to count distinct.
								return tostring(row.zombie.zombieId) or nil
							end,
						},
					},
				})
				:having(function(row)
					-- Debug marker: annotate the square with the current count (requires VisualMarkers).
					-- Normally, side effects inside a query are frowned upon; we do it here for teaching.
					SquareHelpers.record.setSquareMarker(
						row and row.sprite or nil, -- Sprites have coordinates so the marker can use them.
						("zombies=%s"):format(tostring(row and row._count and row._count.zombie or 0))
					)
					return (row._count.zombie or 0) >= 2 -- The aggregate we defined above.
				end)
		end)
		-- ## Direct Action ##
		:removeSpriteObject() -- Effectful helper: removes the observed tile object (hedge) from its square.
		:subscribe(function(observation) -- You still have to subscribe, otherwise the stream is never started.
			print(
				("[DREAM.HedgeTrample] hedge trampled tile=%s zombies=%s"):format(
					tostring(observation.sprite.tileLocation),
					tostring(observation._count.zombie)
				)
			)
		end)

	-- Housekeeping: return a small "handle" so callers can stop the example and inspect its internals.
	return {
		stop = HedgeTrample.stop,
		leases = leases,
		subscription = subscription,
	}
end

function HedgeTrample.stop()
	-- Housekeeping: cleanly tear down everything created by `start()` so we can restart without
	-- duplicate subscriptions or leases continuing to run in the background.
	if subscription and subscription.unsubscribe then
		subscription:unsubscribe()
	end
	-- Make the shutdown idempotent: once stopped, repeated calls do nothing.
	subscription = nil

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

return HedgeTrample
