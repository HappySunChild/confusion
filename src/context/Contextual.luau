local context = require("./types")
local state = require("../core_state/types")

local log_error = require("../core_logging/log_error")
local parse_error = require("../core_logging/parse_error")

type Self<T> = {
	_default: T,
	_values: { [thread]: { T } },
} & context.Contextual<T>

local CLASS = table.freeze({
	type = "Contextual",

	now = function<T>(self: Self<T>): T
		local thread = coroutine.running()
		local value = self._values[thread]

		if value == nil then
			return self._default
		end

		return value[1]
	end,
	execute_with = function<T, R, A...>(self: Self<T>, new: T, callback: (A...) -> R, ...: A...): R
		local thread = coroutine.running()
		local original = self._values[thread]

		self._values[thread] = { new }

		local ok, value = xpcall(callback, parse_error, ...)

		self._values[thread] = original

		if not ok then
			log_error(state.callback_error, value)
		end

		return value
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })
local WEAK_KEYS_METATABLE = table.freeze({ __mode = "k" })

local function Contextual<T>(default: T): context.Contextual<T>
	local new_contextual: Self<T> = setmetatable({
		_default = default,
		_values = setmetatable({}, WEAK_KEYS_METATABLE),
	}, CLASS_METATABLE) :: any

	return new_contextual
end

return Contextual
