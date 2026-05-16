const chrono = require("./types")
const memory = require("../core_memory/types")

const ExternalTime = require("./ExternalTime")

const change = require("../core_graph/change")
const depend = require("../core_graph/depend")
const destructor = require("../core_memory/destructor")
const peek = require("../core_use/peek")

type Self = {
	_timer: chrono.ExternalTime,
} & chrono.Timer

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Timer",
		timeliness = "lazy",

		unpause = function(self: Self)
			if not self.is_paused then
				return
			end

			self._timer:enable()
			self.reference_point = peek(self._timer) - self.cached_value
			self.is_paused = false

			change(self)
		end,
		pause = function(self: Self)
			if self.is_paused then
				return
			end

			self._timer:disable()
			self.is_paused = true

			change(self)
		end,
		zero = function(self: Self)
			self.reference_point = peek(self._timer) :: number
			self.cached_value = 0

			change(self)
		end,

		evaluate = function(self: Self)
			if self.is_paused then
				return false
			end

			depend(self, self._timer)

			const now = peek(self._timer) :: number

			const old_value = self.cached_value
			const new_value = now - self.reference_point

			self.cached_value = new_value

			return old_value ~= new_value
		end,
	}),
})

const function Timer(scope: memory.Scope): chrono.Timer
	const externaltime = ExternalTime(scope)
	const new_timer = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		cached_value = 0,

		is_paused = false,
		reference_point = peek(externaltime),

		_timer = externaltime,
	}, CLASS_MT) :: Self

	const oldest_task = destructor(new_timer)
	new_timer._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	depend(new_timer, externaltime)

	return new_timer
end

return Timer
