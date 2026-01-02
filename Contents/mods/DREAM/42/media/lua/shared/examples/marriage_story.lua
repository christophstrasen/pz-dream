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

	pk.situations.searchIn(WorldObserver)

	leases = {
		churchSeen = wo.factInterest:declare("churchSeen", {
			type = "rooms",
			scope = "onSeeNewRoom",
			cooldown = { desired = 0 },
		}),
		churchEntered = wo.factInterest:declare("churchEntered", {
			type = "players",
			scope = "onPlayerChangeRoom",
			cooldown = { desired = 0 },
		}),
		marriageCastZombies = wo.factInterest:declare("marriageCastZombies", {
			type = "zombies",
			scope = "allLoaded",
			radius = { desired = 25 },
			zRange = { desired = 1 },
			staleness = { desired = 2 },
			cooldown = { desired = 4 },
		}),
	}

	wo.situations.define("churchRoomAvailable", function()
		return wo.observations:rooms():roomTypeIs("church")
	end)

	wo.situations.define("playerJoinsMarriage", function()
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
					:joinWindow({ time = 100 * 1000 }) -- ms
					:groupByEnrich("roomLocation_grouped", function(row)
						return row.player.roomLocation
					end)
					:groupWindow({
						time = 30 * 1000,
						field = "zombie.sourceTime",
					})
					:aggregates({
						count = {
							{
								path = "zombie.outfitName",
								distinctFn = function(row)
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

	pk.actions.define("spawnMarriageScene", function(subject)
		local room = subject and subject.room
		if room then
			RoomHelpers:wrap(room)
		end
		local roomDef = room and room:getRoomDef()
		U.assertf(roomDef, "marriage story roomDef missing for spawn")
		Log:info(
			"spawnMarriageScene roomType=%s roomLocation=%s roomDefId=%s",
			tostring(room and room.name),
			tostring(room and room.roomLocation),
			tostring(room and room.roomDefId)
		)

		local prefab = require("examples/prefabs/marriage")
		prefab.makeForRoomDef(roomDef)
	end)

	pk.actions.define("playWeddingSong", function(subject)
		local playerRoomLocation = subject and subject.player and subject.player.roomLocation
		Log:info("playWeddingSong playerRoomLocation=%s", tostring(playerRoomLocation))

		local player = getPlayer()
		U.assertf(player, "marriage story player missing for song")
		player:Say("<Wedding Song Playing>")
	end)

	promises = {
		spawnMarriage = pk.promise({
			promiseId = "WHEN churchRoomAvailable THEN spawnMarriageScene",
			situationKey = "churchRoomAvailable",
			actionId = "spawnMarriageScene",
			policy = { maxRuns = -1, chance = 1 },
		}),
		playSong = pk.promise({
			promiseId = "WHEN playerJoinsMarriage THEN playWeddingSong",
			situationKey = "playerJoinsMarriage",
			actionId = "playWeddingSong",
			policy = { maxRuns = -1, chance = 1 },
		}),
	}

	return {
		stop = MarriageStory.stop,
		leases = leases,
		promises = promises,
	}
end

function MarriageStory.stop()
	if promises then
		for _, promise in pairs(promises) do
			if promise and promise.forget then
				promise.forget()
			end
		end
	end
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
