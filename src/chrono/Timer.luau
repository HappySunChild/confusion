local chrono = require("./types")
local memory = require("../core_memory/types")

local ExternalTime = require("./ExternalTime")

local change = require("../core_graph/change")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local peek = require("../core_use/peek")

type Self = {
	_paused: boolean,
	_start: number,
	_timer: chrono.ExternalTime,
} & chrono.Timer

local CLASS = table.freeze({
	type = "state",
	kind = "Timer",
	timeliness = "lazy",

	unpause = function(self: Self)
		if not self._paused then
			return
		end

		self._timer:enable()
		self._paused = false

		change(self)
	end,
	pause = function(self: Self)
		if self._paused then
			return
		end

		self._timer:disable()
		self._paused = true

		change(self)
	end,
	zero = function(self: Self)
		self._start = peek(self._timer) :: number
		self._cached_value = 0

		change(self)
	end,

	_evaluate = function(self: Self)
		if self._paused then
			return false
		end

		depend(self, self._timer)

		local now = peek(self._timer) :: number

		local old_value = self._cached_value
		local new_value = now - self._start

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

		_paused = false,
		_start = peek(externaltime),

		_timer = externaltime,
	}, CLASS_METATABLE) :: Self

	table.insert(scope, destructor(new_timer))

	depend(new_timer, externaltime)

	return new_timer
end

return Timer
