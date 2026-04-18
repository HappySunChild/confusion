local keyframes = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local destructor = require("../core_memory/destructor")
local evaluate_keyframes = require("./evaluate_keyframes")
local generic_use = require("../core_use/generic_use")
local is_similar = require("../core_state/is_similar")

type Self<T> = {
	_alpha: state.UsedAs<number>,
	_keyframes: { T },

	_use: state.Use,
} & keyframes.Keyframes<T>

local CLASS = table.freeze({
	type = "state",
	kind = "Keyframes",
	timeliness = "lazy",

	_evaluate = function<T>(self: Self<T>): boolean
		if self.scope == nil then
			return false
		end

		local use = self._use

		local old_value = self._cached_value
		local new_value = evaluate_keyframes(use(self._alpha), self._keyframes, use)

		self._cached_value = new_value

		return not is_similar(old_value, new_value)
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Keyframes<T>(scope: memory.Scope, alpha: state.UsedAs<number>, keyframes: { T }): keyframes.Keyframes<T> | T
	local new_keyframes: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_alpha = alpha,
		_keyframes = keyframes,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_keyframes)

	new_keyframes._oldest_task = oldest_task
	new_keyframes._use = generic_use(new_keyframes)

	table.insert(scope, oldest_task())

	return new_keyframes
end

return Keyframes
