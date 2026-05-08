local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

local ExternalTime = require("./ExternalTime")
local make_capture = require("../core_graph/make_capture")
local make_getter = require("../core_graph/make_getter")
local notify_observers = require("../core_graph/notify_observers")

local function Timer(scope: memory.Scope): (graph.usegetter<number>, () -> ())
	local is_valid = false
	local reference_point = os.clock()
	local cached_version: number = -1
	local cached_value: number = 0

	local now = ExternalTime(scope)

	local observers: graph.Set<graph.observer> = {}
	local sources: graph.Set<graph.source> = {}

	local function observer()
		if not is_valid then
			return
		end

		is_valid = false
		notify_observers(observers)
	end

	local capture = make_capture(sources, observer)

	local function evaluate()
		if is_valid then
			return
		end

		is_valid = true

		cached_version = os.clock()
		cached_value = now(capture) - reference_point
	end

	local function source(observer: graph.observer?, remove: boolean?)
		if observer ~= nil then
			if remove == true then
				observers[observer] = nil
			else
				observers[observer] = true
			end

			return 0
		end

		evaluate()

		return cached_version
	end

	local function rawgetter(other_capture: graph.capture?)
		if other_capture ~= nil then
			observers[other_capture(source)] = true
		end

		evaluate()

		return cached_value
	end

	local function zero()
		reference_point = os.clock()

		notify_observers(observers)
	end

	return make_getter(rawgetter), zero
end

return Timer
