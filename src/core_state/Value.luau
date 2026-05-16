const memory = require("../core_memory/types")
const state = require("./types")

const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")
const is_similar = require("./is_similar")

type Self<T> = state.Value<T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Value",
		timeliness = "lazy",

		using = table.freeze({}),

		set = function<T>(self: Self<T>, new_value: T): T
			if not is_similar(new_value, self._cached_value) then
				self._cached_value = new_value

				change(self)
			end

			return new_value
		end,
		update = function<T>(self: Self<T>, updater: (T) -> T): T
			return self:set(updater(self._cached_value))
		end,
		_evaluate = function()
			return true
		end,
	}),
})

const function Value<T>(scope: memory.Scope, initial_value: T): state.Value<T>
	const new_value: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		_cached_value = initial_value,
	}, CLASS_MT) :: any

	const oldest_task = destructor(new_value)
	new_value._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_value
end

return Value
