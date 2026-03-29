local chrono = require("./types")
local memory = require("../core_memory/types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local change = require("../core_graph/change")
local destructor = require("../core_memory/destructor")

type Self = chrono.ExternalTime

local ALL_TIMERS = {}

local CLASS = {
	type = "state",
	kind = "ExternalTime",
	timeliness = "lazy",
	using = table.freeze({}),
	_cached_value = ExternalScheduler.get_last_update(),

	enable = function(self: Self)
		ALL_TIMERS[self] = true
	end,
	disable = function(self: Self)
		ALL_TIMERS[self] = nil
	end,
	is_enabled = function(self: Self)
		return ALL_TIMERS[self] ~= nil
	end,

	_evaluate = function(self: Self)
		return true
	end,
}
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_externaltime(externaltime: Self)
	ALL_TIMERS[externaltime] = nil
end

local function ExternalTime(scope: memory.Scope): chrono.ExternalTime
	local new_externaltime = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
	}, CLASS_METATABLE) :: Self

	ALL_TIMERS[new_externaltime] = true

	table.insert(scope, destructor(new_externaltime, destroy_externaltime))

	return new_externaltime
end

ExternalScheduler.bind_to_update_step(function(now: number)
	CLASS._cached_value = now

	for timer in ALL_TIMERS do
		change(timer)
	end
end)

return ExternalTime
