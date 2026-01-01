-- marriage_story.lua - demo: spawn a marriage scene when a church room is seen,
-- then play a wedding song once the player enters that room.
--[[ Usage in PZ console:
handle = require("examples/marriage_story").start()
handle.stop()
]]

local U = require("DREAMBase/util")
local RoomHelpers = require("WorldObserver/helpers/room")

local MarriageStory = {}

local leases
local promises

function MarriageStory.start()
	MarriageStory.stop()

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
			type = "rooms",
			scope = "onPlayerChangeRoom",
			target = { player = { id = 0 } },
			cooldown = { desired = 0 },
		}),
	}

	wo.situations.define("churchRoomAvailable", function()
		return wo.observations:rooms():roomTypeIs("church"):withOccurrenceKey(function(observation)
			local room = observation and observation.room
			local roomLocation = room and room.roomLocation
			if roomLocation == nil then
				return nil
			end
			return "church@" .. tostring(roomLocation)
		end)
	end)

	wo.situations.define("playerJoinsMarriage", function()
		return wo.observations:rooms():roomTypeIs("church"):withOccurrenceKey(function(observation)
			local room = observation and observation.room
			local roomLocation = room and room.roomLocation
			if roomLocation == nil then
				return nil
			end
			return "church@" .. tostring(roomLocation)
		end)
	end)

	pk.actions.define("spawnMarriageScene", function(subject)
		local room = subject and subject.room
		if room then
			RoomHelpers:wrap(room)
		end
		local roomDef = room and room:getRoomDef()
		U.assertf(roomDef, "marriage story roomDef missing for spawn")

		local prefab = require("examples/prefabs/marriage")
		prefab.makeForRoomDef(roomDef)
	end)

	pk.actions.define("playWeddingSong", function()
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
end

return MarriageStory
