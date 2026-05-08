local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

local disconnect_observers = require("../core_graph/disconnect_observers")
local notify_observers = require("../core_graph/notify_observers")

local scheduler = require("../core_graph/scheduler")
local flush = scheduler.flush

local function Value<T>(scope: memory.Scope, initial_value: T): (graph.getter<T>, graph.setter<T>)
	local cached_version = -1
	local cached_value: T = initial_value

	local observer_set: graph.Set<graph.observer> = {}

	local function source(observer: graph.observer?, remove: boolean?)
		if observer ~= nil then
			if remove == true then
				observer_set[observer] = nil
			else
				observer_set[observer] = true
			end

			return 0
		end

		return cached_version
	end

	local function getter(other_capture: graph.capture?): T
		if other_capture ~= nil then
			observer_set[capture(source)] = true
		end

		return cached_value
	end

	local function setter(new_value: T)
		if new_value == cached_value then
			return
		end

		cached_version = os.clock()
		cached_value = new_value

		notify_observers(observer_set)
		flush()
	end

	local function oldest_task()
		disconnect_observers(observer_set, source)
	end

	table.insert(scope, oldest_task)

	return getter, setter
end

return Value
