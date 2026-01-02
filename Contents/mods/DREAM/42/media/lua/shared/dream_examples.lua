-- DREAM examples runner
--
-- Paste-ready console commands (Project Zomboid debug console):
--[[
require("DREAMBase/log").setLevel("info") -- Skip this unless you want very chatty console output
d = require("dream_examples")
d:list()                   -- prints examples with numeric IDs
d:start(1)                 -- start by numeric ID (or d:start("police_road_cone"))
d:stop()                   -- stop the active example
d:reset()                  -- reset promises of thee active example (if supported)
d:nuke()                   -- reset + clear persisted state of _all_ promises (if supported)
--]]

local BaseLog = require("DREAMBase/log")
local Log = BaseLog.withTag("DREAM.Examples")

local registry = {
	police_road_cone = {
		module = "examples/police_road_cone",
		description = "Police zombies spawn cones on roads",
	},
	hedge_trample = {
		module = "examples/hedge_trample",
		description = "Zombies trample hedges when they crowd a tile",
	},
	marriage_story = {
		module = "examples/marriage_story",
		description = "Spawn a wedding scene and play a song in church rooms",
	},
}

local ordered_ids = { "police_road_cone", "hedge_trample", "marriage_story" }

local state = {
	activeId = nil,
	activeHandle = nil,
	activeModule = nil,
	activeOpts = nil,
}

local function emitInfo(fmt, ...)
	if BaseLog and type(BaseLog.supressBelow) == "function" then
		local args = { ... }
		BaseLog.supressBelow("info", function()
			Log:info(fmt, unpack(args))
		end)
	else
		Log:info(fmt, ...)
	end
end

local function resolveExample(id)
	if type(id) == "number" then
		local index = math.floor(id)
		local key = ordered_ids[index]
		if key and registry[key] then
			return key, registry[key]
		end
		return nil, "unknown example id"
	end
	if type(id) ~= "string" or id == "" then
		return nil, "example id required"
	end
	if registry[id] then
		return id, registry[id]
	end
	for key, entry in pairs(registry) do
		if entry.module == id then
			return key, entry
		end
	end
	return nil, "unknown example id"
end

local function startExample(selfOrId, idOrOpts, optsMaybe)
	local id = selfOrId
	local opts = idOrOpts
	if type(selfOrId) == "table" and (type(idOrOpts) == "number" or type(idOrOpts) == "string") then
		id = idOrOpts
		opts = optsMaybe
	end

	local resolvedId, entry = resolveExample(id)
	if not resolvedId then
		Log:warn("unknown example id=%s", tostring(id))
		return nil
	end
	if state.activeHandle then
		Log:warn("example already running id=%s", tostring(state.activeId))
		return state.activeHandle
	end

	local mod = require(entry.module)
	if not (mod and type(mod.start) == "function") then
		Log:warn("example missing start id=%s", tostring(resolvedId))
		return nil
	end

	local handle = mod.start(opts)
	if handle == nil then
		Log:warn("example start failed id=%s", tostring(resolvedId))
		return nil
	end
	state.activeId = resolvedId
	state.activeHandle = handle
	state.activeModule = mod
	state.activeOpts = opts
	emitInfo("example started id=%s", tostring(resolvedId))
	return handle
end

local function stopActive()
	if not state.activeHandle then
		Log:warn("no active example to stop")
		return nil
	end

	local handle = state.activeHandle
	if handle and type(handle.stop) == "function" then
		handle:stop()
	end

	emitInfo("example stopped id=%s", tostring(state.activeId))
	state.activeId = nil
	state.activeHandle = nil
	state.activeModule = nil
	state.activeOpts = nil
	return true
end

local function resetActive()
	if not state.activeId then
		Log:warn("no active example to reset")
		return nil
	end

	local handle = state.activeHandle
	if handle and type(handle.reset) == "function" then
		local nextHandle = handle:reset()
		if nextHandle ~= nil then
			state.activeHandle = nextHandle
		end
		emitInfo("example reset id=%s", tostring(state.activeId))
		return state.activeHandle
	end

	local mod = state.activeModule
	if mod and type(mod.reset) == "function" then
		local nextHandle = mod.reset(handle, state.activeOpts)
		if nextHandle ~= nil then
			state.activeHandle = nextHandle
		end
		emitInfo("example reset id=%s", tostring(state.activeId))
		return state.activeHandle
	end

	local activeId = state.activeId
	local activeOpts = state.activeOpts
	Log:warn("example reset not supported id=%s restarting", tostring(activeId))
	return stopActive() and startExample(activeId, activeOpts)
end

local function nukeActive()
	if not state.activeId then
		Log:warn("no active example to nuke")
		return nil
	end

	local handle = state.activeHandle
	if handle and type(handle.nuke) == "function" then
		local nextHandle = handle:nuke()
		if nextHandle ~= nil then
			state.activeHandle = nextHandle
		end
		emitInfo("example nuked id=%s", tostring(state.activeId))
		return state.activeHandle
	end

	local mod = state.activeModule
	if mod and type(mod.nuke) == "function" then
		local nextHandle = mod.nuke(handle, state.activeOpts)
		if nextHandle ~= nil then
			state.activeHandle = nextHandle
		end
		emitInfo("example nuked id=%s", tostring(state.activeId))
		return state.activeHandle
	end

	Log:warn("example nuke not supported id=%s falling back to reset", tostring(state.activeId))
	return resetActive()
end

local function list()
	local out = {}
	emitInfo("DREAM example runner")
	emitInfo("Commands")
	emitInfo("list() --prints examples with numeric IDs")
	emitInfo("start(<id or name> -- start by numeric ID or full name")
	emitInfo("stop() -- stop the active example")
	emitInfo("reset() -- reset promises of thee active example")
	emitInfo("nuke() -- reset + clear persisted state of _all_ promises")
	emitInfo("Examples")
	for i = 1, #ordered_ids do
		local id = ordered_ids[i]
		out[i] = id
		local entry = registry[id]
		if entry then
			emitInfo("  %d) %s  %s", i, tostring(id), tostring(entry.description))
		end
	end
	return out
end

local examples = {}
for i = 1, #ordered_ids do
	local entry = registry[ordered_ids[i]]
	if entry then
		examples[#examples + 1] = entry.module
	end
end

return {
	name = "DREAM examples placeholder",
	-- Keep these as slash-style require paths (Build 42 friendly).
	examples = examples,
	registry = registry,
	list = list,
	start = startExample,
	stop = stopActive,
	reset = resetActive,
	nuke = nukeActive,
}
