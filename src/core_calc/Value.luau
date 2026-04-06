local calc = require("./types")
local memory = require("../core_memory/types")

local change = require("../core_graph/change")
local destructor = require("../core_memory/destructor")
local is_similar = require("./is_similar")

type Self<T> = calc.Value<T>

local CLASS = table.freeze({
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
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Value<T>(scope: memory.Scope, initial_value: T): calc.Value<T>
	local new_value: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		_cached_value = initial_value,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_value)
	new_value._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_value
end

return Value
