local graph = require("../core_graph/types")
local memory = require("../core_memory/types")
local state = require("./types")

local check_outdated = require("../core_graph/check_outdated")
local cleanup = require("../core_memory/cleanup")
local derive_scope = require("../core_memory/derive_scope")
local disconnect_observers = require("../core_graph/disconnect_observers")
local disconnect_sources = require("../core_graph/disconnect_sources")
local is_similar = require("./is_similar")
local log_error = require("../core_logging/log_error")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local maintain_sources = require("../core_graph/maintain_sources")
local make_capture = require("../core_graph/make_capture")
local make_use = require("../core_use/make_use")
local notify_observers = require("../core_graph/notify_observers")
local parse_error = require("../core_logging/parse_error")

local function Computed<S, T>(scope: memory.Scope<S>, processor: state.ComputedProcessor<S, T>): graph.getter<T>
	local validity: graph.Validity = "invalid"
	local absolute_version: number = -1
	local cached_version: number = -1
	local cached_value: T? = nil
	local active_scope: memory.Scope<S>? = nil

	local observers: graph.Set<graph.observer> = {}
	local sources: graph.Set<graph.source> = {}

	local function observer(source: graph.source?)
		if source ~= nil then
			sources[source] = nil
			return
		end

		if validity == "invalid" then
			return
		end

		validity = "invalid"
		notify_observers(observers)
	end

	local use = make_use(make_capture(sources, observer))

	local function evaluate()
		if validity == "busy" then
			log_error(graph.infinite_loop)
		elseif validity == "valid" then
			return
		end

		local should_recompute = check_outdated(sources, absolute_version)
		if not should_recompute then
			validity = "valid"

			maintain_sources(sources, observer)
			return
		end

		validity = "busy"

		disconnect_sources(sources, observer)

		local computation_scope = derive_scope(scope)
		local ok, new_value = xpcall(processor, parse_error, use, computation_scope)

		validity = "valid"

		if not ok then
			cleanup(computation_scope)

			log_error_nonfatal(state.callback_error, new_value)

			return
		end

		cleanup(active_scope)

		cached_value = new_value
		active_scope = computation_scope

		absolute_version = os.clock()

		if not is_similar(new_value, cached_value) then
			cached_version = os.clock()
		end
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

	local function getter(other_capture: graph.capture?)
		evaluate()

		if other_capture ~= nil then
			observers[other_capture(source)] = true
		end

		return cached_value
	end

	local function oldest_task()
		disconnect_sources(sources, observer)
		disconnect_observers(observers, source)
		cleanup(active_scope)
	end

	table.insert(scope, oldest_task)

	return getter
end

return Computed
