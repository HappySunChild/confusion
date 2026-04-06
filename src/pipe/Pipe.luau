local calc = require("../core_calc/types")
local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")
local pipeline = require("./types")
local tweens = require("../motion_tweens/types")

local Computed = require("../core_calc/Computed")
local ForKeys = require("../iter_for/ForKeys")
local ForPairs = require("../iter_for/ForPairs")
local ForValues = require("../iter_for/ForValues")
local Spring = require("../motion_springs/Spring")
local Tween = require("../motion_tweens/Tween")

local inner_scope = require("../core_memory/inner_scope")

type Self<S, T> = {
	_current: calc.UsedAs<T>,
	_internal_scope: memory.Scope<S>,
} & pipeline.Pipe<S, T>

local CLASS = table.freeze({
	type = "Pipe",

	resolve = function<T>(self: Self<any, T>): T
		return self._current
	end,
	modify = function<S, T>(
		self: Self<S, T>,
		processor: (latest: T, scope: memory.Scope<S>) -> any
	): Self<S, T>
		self._current = processor(self._current, self._internal_scope)
		return self
	end,

	map = function<S, T, O>(
		self: Self<S, T>,
		processor: (value: T, use: calc.Use, scope: memory.Scope<S>) -> O
	): Self<S, O>
		local latest = self._current
		self._current = Computed(self._internal_scope, function(use, scope)
			return processor(use(latest), use, scope)
		end)

		return self
	end,

	spring = function<S, T>(
		self: Self<S, T>,
		speed: calc.UsedAs<number>?,
		damping: calc.UsedAs<number>?
	): Self<S, T>
		self._current = Spring(self._internal_scope, self._current, speed, damping)

		return self
	end,
	tween = function<S, T>(self: Self<S, T>, info: calc.UsedAs<tweens.TweenInfo>): Self<S, T>
		self._current = Tween(self._internal_scope, self._current, info)

		return self
	end,

	for_pairs = function<S, IK, IV, OK, OV>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForPairsProcessor<
			unknown,
			IK,
			IV,
			OK,
			OV
		>
	): Self<S, { [OK]: OV }>
		self._current = ForPairs(self._internal_scope, self._current, processor)

		return self
	end,
	for_values = function<S, IK, IV, OV>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForValuesProcessor<S, IV, OV>
	): Self<S, { [IK]: OV }>
		self._current = ForValues(self._internal_scope, self._current, processor)

		return self
	end,
	for_keys = function<S, IK, IV, OK>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForKeysProcessor<S, IK, OK>
	): Self<S, { [OK]: IV }>
		self._current = ForKeys(self._internal_scope, self._current, processor)

		return self
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Pipe<S, T>(scope: memory.Scope<S>, initial_value: calc.UsedAs<T>): pipeline.Pipe<S, T>
	local new_pipe: Self<S, T> = setmetatable({
		_internal_scope = inner_scope(scope),
		_current = initial_value,
	}, CLASS_METATABLE) :: any

	return new_pipe
end

return Pipe
