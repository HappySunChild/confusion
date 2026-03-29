local calc = require("../core_calc/types")
local keyframes = require("./types")
local memory = require("../core_memory/types")

local cast_to_state = require("../core_calc/cast_to_state")
local destructor = require("../core_memory/destructor")
local dissolving_use = require("../core_use/dissolving_use")
local evaluate_keyframes = require("./evaluate_keyframes")
local generic_use = require("../core_use/generic_use")
local is_similar = require("../core_calc/is_similar")

type Self<T> = {
	_alpha: calc.UsedAs<number>,
	_keyframes: { T },

	_use: calc.Use,
} & keyframes.Keyframes<T>

local CLASS = table.freeze({
	type = "State",
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

local function check_dissolvable<T>(alpha: calc.UsedAs<number>, keyframes: { T }): (boolean, T?)
	if cast_to_state(alpha) ~= nil then
		return false, nil
	end

	local ok, value = pcall(evaluate_keyframes, alpha :: number, keyframes, dissolving_use)

	if not ok then
		return false, nil
	end

	return true, value
end

local function Keyframes<T>(
	scope: memory.Scope,
	alpha: calc.UsedAs<number>,
	keyframes: { T }
): keyframes.Keyframes<T> | T
	local can_dissolve, constant = check_dissolvable(alpha, keyframes)

	if can_dissolve then
		return constant
	end

	local new_keyframes: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_alpha = alpha,
		_keyframes = keyframes,
	}, CLASS_METATABLE) :: any

	new_keyframes._use = generic_use(new_keyframes)

	table.insert(scope, destructor(new_keyframes))

	return new_keyframes
end

return Keyframes
