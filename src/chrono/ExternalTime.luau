const chrono = require("./types")
const memory = require("../core_memory/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")

type Self = chrono.ExternalTime

const ALL_TIMERS = {}

const CLASS = {
	type = "state",
	kind = "ExternalTime",
	timeliness = "lazy",
	using = table.freeze({}),
	cached_value = ExternalScheduler.get_last_update(),

	enable = function(self: Self)
		ALL_TIMERS[self] = true
	end,
	disable = function(self: Self)
		ALL_TIMERS[self] = nil
	end,
	is_enabled = function(self: Self)
		return ALL_TIMERS[self] ~= nil
	end,
	evaluate = function(self: Self)
		return true
	end,
}
const CLASS_MT = table.freeze({ __index = CLASS })

ExternalScheduler.bind_to_update_step(function(now: number)
	CLASS.cached_value = now

	for timer in ALL_TIMERS do
		change(timer)
	end
end)

const function destroy_externaltime(externaltime: Self)
	ALL_TIMERS[externaltime] = nil
end

const function ExternalTime(scope: memory.Scope): chrono.ExternalTime
	const new_externaltime = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
	}, CLASS_MT) :: Self

	ALL_TIMERS[new_externaltime] = true

	const oldest_task = destructor(new_externaltime, destroy_externaltime)
	new_externaltime._oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_externaltime
end

return ExternalTime
