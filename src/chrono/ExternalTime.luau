local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local disconnect_observers = require("../core_graph/disconnect_observers")
local notify_observers = require("../core_graph/notify_observers")

local scheduler = require("../core_graph/scheduler")
local flush = scheduler.flush

local ALL_TIMERS = {}
local current_time = 0

local function update_all_timers(now: number)
	current_time = now

	for update in ALL_TIMERS do
		update()
	end

	flush()
end

local function ExternalTime(scope: memory.Scope): graph.getter<number>
	local observers: graph.ObserverSet = {}

	local function source(observer: graph.observer?, remove: boolean?)
		if observer ~= nil then
			if remove == true then
				observers[observer] = nil
			else
				observers[observer] = true
			end

			return 0
		end

		return current_time
	end

	local function getter(capture: graph.capture?)
		if capture ~= nil then
			observers[capture(source)] = true
		end

		return current_time
	end

	local function update()
		notify_observers(observers)
	end

	ALL_TIMERS[update] = true

	local function oldest_task()
		disconnect_observers(observers, source)
		ALL_TIMERS[update] = nil
	end

	table.insert(scope, oldest_task)

	return getter
end

ExternalScheduler.bind_to_update_step(update_all_timers)

return ExternalTime
