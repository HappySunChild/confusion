local chrono = require("./types")
local memory = require("../core_memory/types")

local ExternalTime = require("./ExternalTime")

local change = require("../core_graph/change")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local peek = require("../core_use/peek")

type Self = {
	_timer: chrono.ExternalTime,
} & chrono.Timer

local CLASS = table.freeze({
	type = "state",
	kind = "Timer",
	timeliness = "lazy",

	unpause = function(self: Self)
		if not self.is_paused then
			return
		end

		self._timer:enable()
		self.reference_point = peek(self._timer) - self._cached_value
		self.is_paused = false

		change(self)
	end,
	pause = function(self: Self)
		if self.is_paused then
			return
		end

		self._timer:disable()
		self.is_paused = true
	end,
	zero = function(self: Self)
		self.reference_point = peek(self._timer) :: number
		self._cached_value = 0

		change(self)
	end,

	_evaluate = function(self: Self)
		if self.is_paused then
			return false
		end

		depend(self, self._timer)

		local now = peek(self._timer) :: number

		local old_value = self._cached_value
		local new_value = now - self.reference_point

		self._cached_value = new_value

		return old_value ~= new_value
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Timer(scope: memory.Scope): chrono.Timer
	local externaltime = ExternalTime(scope)
	local new_timer = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},
		_cached_value = 0,

		is_paused = false,
		reference_point = peek(externaltime),

		_timer = externaltime,
	}, CLASS_METATABLE) :: Self

	local oldest_task = destructor(new_timer)
	new_timer._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	depend(new_timer, externaltime)

	return new_timer
end

return Timer
