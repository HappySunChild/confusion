const context = require("./types")
const state = require("../core_state/types")

const log_error = require("../core_logging/log_error")
const parse_error = require("../core_logging/parse_error")

type Self<T> = {
	_default: T,
	_values: { [thread]: { T } },
} & context.Contextual<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "Contextual",

		now = function<T>(self: Self<T>): T
			const thread = coroutine.running()
			const value = self._values[thread]

			if value == nil then
				return self._default
			end

			return value[1]
		end,
		execute_with = function<T, R, A...>(self: Self<T>, new: T, callback: (A...) -> R, ...: A...): R
			const thread = coroutine.running()
			const original = self._values[thread]

			self._values[thread] = { new }

			const ok, value = xpcall(callback, parse_error, ...)

			self._values[thread] = original

			if not ok then
				log_error(state.callback_error, value)
			end

			return value
		end,
	}),
})
const WEAK_KEYS_MT = table.freeze({ __mode = "k" })

const function Contextual<T>(default: T): context.Contextual<T>
	const new_contextual: Self<T> = setmetatable({
		_default = default,
		_values = setmetatable({}, WEAK_KEYS_MT),
	}, CLASS_MT) :: any

	return new_contextual
end

return Contextual
