-- marriage_story.lua - demo: spawn a marriage scene when a church room is seen,
-- then play a wedding song once the player enters that room.
--[[ Usage in PZ console:
require("DREAMBase/log").setLevel("info")
handle = require("examples/marriage_story").start()
handle.stop()
]]

local U = require("DREAMBase/util")
local Log = require("DREAMBase/log").withTag("DREAM.MarriageStory")
local RoomHelpers = require("WorldObserver/helpers/room")
local MarriageStory = {}
local leases
local promises

function MarriageStory.start()
	MarriageStory.stop()
	Log:info("start")

	local PromiseKeeper = require("PromiseKeeper")
	local WorldObserver = require("WorldObserver")

	local namespace = "DREAM.MarriageStory"
	local pk = PromiseKeeper.namespace(namespace)
	local wo = WorldObserver.namespace(namespace)

	-- PromiseKeeper will look up situations in this registry (provided by WorldObserver).
	pk.situations.searchIn(WorldObserver)

	-- ## Fact Layer ##

	-- Interests choose which facts are produced, how and why.
	leases = {
		churchSeen = wo.factInterest:declare("onSeeNewRoom to find Churches", {
			type = "rooms",
			scope = "onSeeNewRoom",
			cooldown = { desired = 0 },
		}),
		churchEntered = wo.factInterest:declare("onPlayerChangeRoom To check if player joins a marriage", {
			type = "players",
			scope = "onPlayerChangeRoom",
			cooldown = { desired = 0 },
		}),
		-- This scope is more "interesting"
		marriageCastZombies = wo.factInterest:declare("Zeds in 25 radius to check if they are Marriage Casts", {
			type = "zombies",
			scope = "allLoaded",
			radius = { desired = 25 },
			zRange = { desired = 1 },
			staleness = { desired = 2 },
			cooldown = { desired = 4 },
		}),
	}

	-- ## Situation Layer ##

	wo.situations.define("churchRoomAvailable", function()
		-- Simple situation: "seen a church room" is just a single stream filter.
		return wo.observations:rooms():roomTypeIs("church")
	end)

	wo.situations.define("playerJoinsMarriage", function()
		-- Derived situation: join player + zombie streams by roomLocation, then apply group rules.
		return wo.observations
			:derive({
				player = wo.observations:players():playerFilter(function(player)
					return player and player.roomName == "church" and player.roomLocation ~= nil
				end),
				zombie = wo.observations:zombies():zombieFilter(function(zombie)
					local outfit = zombie and zombie.outfitName
					return zombie and zombie.roomLocation ~= nil and (outfit == "Groom" or outfit == "WeddingDress")
				end),
			}, function(lqr)
				return lqr
					.player
					:innerJoin(lqr.zombie)
					:using({ player = "roomLocation", zombie = "roomLocation" })
					:joinWindow({ time = 100 * 1000 }) -- ms. If this is smaller than fact staleness/cooldown, joins may become flaky.
					:groupByEnrich("roomLocation_grouped", function(row)
						return row.player.roomLocation
					end)
					:groupWindow({
						time = 30 * 1000, -- ms. Sliding window for aggregates, relative to the time in the `field`.
						field = "zombie.sourceTime",
					})
					:aggregates({
						count = {
							{
								path = "zombie.outfitName", -- `path` chooses which field exists for "count" bookkeeping.
								distinctFn = function(row) -- Same Zed can be observed multiple times. We have to count distinct.
									return row and row.zombie and row.zombie.outfitName or nil
								end,
							},
						},
					})
					:having(function(row)
						return (row._count.zombie or 0) >= 2
					end)
			end)
			:withOccurrenceKey(function(observation)
				return observation.player.roomLocation
			end)
	end)

	-- ## Action Layer ##

	pk.actions.define("spawnMarriageScene", function(subject)
		-- Actions receive the situation "subject" (here the observation record)
		local room = subject and subject.room
		RoomHelpers:wrap(room) --adds convenience methods
		local roomDef = room and room:getRoomDef()
		U.assertf(roomDef, "marriage story roomDef missing for spawn")
		Log:info(
			"spawnMarriageScene roomType=%s roomLocation=%s roomDefId=%s",
			tostring(room and room.name),
			tostring(room and room.roomLocation),
			tostring(room and room.roomDefId)
		)

		local marriageScene = require("examples/scenes/marriage")
		marriageScene.makeForRoomDef(roomDef)
	end)

	pk.actions.define("playWeddingSong", function(subject)
		-- Actions can read the subject, but can also call engine APIs directly.
		local playerRoomLocation = subject and subject.player and subject.player.roomLocation
		Log:info("playWeddingSong playerRoomLocation=%s", tostring(playerRoomLocation))

		local player = getPlayer()
		U.assertf(player, "marriage story player missing for song")
		player:Say("<Wedding Song Playing . . .>")
		getSoundManager():PlaySound("DREAM_examples_weddingMarchMusicBox", false, 1.0)
	end)

	-- ## Promises glue situations and actions together ##

	promises = {
		spawnMarriage = pk.promise({
			promiseId = "WHEN churchRoomAvailable THEN spawnMarriageScene",
			situationKey = "churchRoomAvailable",
			actionId = "spawnMarriageScene",
			-- maxRuns=-1 means "forever"; the situation itself controls cadence.
			policy = { maxRuns = -1, chance = 1 },
		}),
		playSong = pk.promise({
			promiseId = "WHEN playerJoinsMarriage THEN playWeddingSong",
			situationKey = "playerJoinsMarriage",
			actionId = "playWeddingSong",
			policy = { maxRuns = -1, chance = 1 },
		}),
	}

	-- Housekeeping: return a small "handle" so callers (like `dream_examples.lua`) can manage lifecycle
	-- and inspect what this example created (useful for debugging in the console).
	return {
		stop = MarriageStory.stop,
		leases = leases,
		promises = promises,
	}
end

function MarriageStory.stop()
	-- Housekeeping: cleanly tear down everything created by `start()` so we can restart without
	-- duplicate listeners, leases, or persisted promises continuing to run in the background.
	if promises then
		for _, promise in pairs(promises) do
			if promise and promise.forget then
				promise.forget()
			end
		end
	end
	-- Make the shutdown idempotent: once stopped, repeated calls do nothing.
	promises = nil

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

return MarriageStory
