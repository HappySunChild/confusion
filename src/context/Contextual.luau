const context = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const parse_error = require("../core_logging/parse_error")

type Self<T> = {
	default: T,
	values: { [thread]: { T } },
} & context.Contextual<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "Contextual",

		now = function<T>(self: Self<T>): T
			const current_thread = coroutine.running()
			const value = self.values[current_thread]

			if value == nil then
				return self.default
			end

			return value[1]
		end,
		execute_with = function<T, R, A...>(self: Self<T>, new: T, callback: (A...) -> R, ...: A...): R
			const thread = coroutine.running()
			const original = self.values[thread]

			self.values[thread] = { new }

			const ok, value_or_err = xpcall(callback, parse_error, ...)

			self.values[thread] = original

			if not ok then
				log_error(context.callback_error, value_or_err, { value = new })
			end

			return value_or_err
		end,
	}),
})
const WEAK_KEYS_MT = table.freeze({ __mode = "k" })

const function Contextual<T>(default: T): context.Contextual<T>
	const new_contextual: Self<T> = setmetatable({
		default = default,
		values = setmetatable({}, WEAK_KEYS_MT),
	}, CLASS_MT) :: any

	return new_contextual
end

return Contextual
