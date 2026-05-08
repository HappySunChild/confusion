local graph = require("./types")
local memory = require("../core_memory/types")

local disconnect_sources = require("./disconnect_sources")
local is_outdated = require("./is_outdated")
local maintain_sources = require("./maintain_sources")
local make_capture = require("./make_capture")
local make_use = require("../core_use/make_use")

local scheduler = require("./scheduler")
local schedule = scheduler.schedule

local function Observer(scope: memory.Scope, callback: graph.ObserverCallback)
	local is_disconnected: boolean = false
	local is_scheduled: boolean = false
	local cached_version: number = -1

	local source_set: graph.Set<graph.source> = {}

	local evaluate = nil -- pretty horrific forwards declaration, oh well

	local function observer(source: graph.source?)
		if source ~= nil then
			source_set[source] = nil
			return
		end

		if is_disconnected or is_scheduled then
			return
		end

		is_scheduled = true
		schedule(evaluate)
	end

	local use = make_use(make_capture(source_set, observer))

	function evaluate()
		if is_disconnected then
			return
		end

		is_scheduled = false

		local should_recompute = is_outdated(cached_version, source_set)

		if not should_recompute then
			maintain_sources(source_set, observer)
			return
		end

		disconnect_sources(source_set, observer)
		cached_version = os.clock()
		callback(use)
	end

	local function disconnect()
		if is_disconnected then
			return
		end

		is_disconnected = true
		disconnect_sources(source_set, observer)
	end

	evaluate()

	local function oldest_task()
		disconnect_sources(source_set, observer)
		disconnect()
	end

	table.insert(scope, oldest_task)

	return disconnect
end

return Observer
