local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local disconnect_observers = require("../core_graph/disconnect_observers")
local notify_observers = require("../core_graph/notify_observers")

local scheduler = require("../core_graph/scheduler")
local flush = scheduler.flush

local ALL_TIMER_OBSERVERS: graph.Set<graph.Set<graph.source>> = {}

local current_version = -1
local current_time = 0

local function update_all_timers(now: number)
	current_time = now
	current_version = os.clock()

	for observers in ALL_TIMER_OBSERVERS do
		notify_observers(observers)
	end

	flush()
end

ExternalScheduler.bind_to_update_step(update_all_timers)

local function ExternalTime(scope: memory.Scope): graph.rawgetter<number>
	local observers: graph.Set<graph.observer> = {}

	local function source(observer: graph.observer?, remove: boolean?)
		if observer ~= nil then
			if remove == true then
				observers[observer] = nil
			else
				observers[observer] = true
			end

			return 0
		end

		return current_version
	end

	local function rawgetter(capture: graph.capture?)
		if capture ~= nil then
			observers[capture(source)] = true
		end

		return current_time
	end

	ALL_TIMER_OBSERVERS[observers] = true

	local function oldest_task()
		ALL_TIMER_OBSERVERS[observers] = nil
		disconnect_observers(observers, source)
	end

	table.insert(scope, oldest_task)

	return rawgetter
end

return ExternalTime
