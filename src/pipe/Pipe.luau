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
	_latest: calc.UsedAs<T>,
	_internal_scope: memory.Scope<S>,
} & pipeline.Pipe<S, T>

local CLASS = table.freeze({
	type = "Pipe",

	spring = function<S, T>(
		self: Self<S, T>,
		speed: calc.UsedAs<number>?,
		damping: calc.UsedAs<number>?
	): Self<S, T>
		self._latest = Spring(self._internal_scope, self._latest, speed, damping)

		return self
	end,
	tween = function<S, T>(self: Self<S, T>, info: calc.UsedAs<tweens.TweenInfo>): Self<S, T>
		self._latest = Tween(self._internal_scope, self._latest, info)

		return self
	end,

	map = function<S, T, O>(
		self: Self<S, T>,
		processor: (value: T, use: calc.Use, scope: memory.Scope<S>) -> O
	): Self<S, O>
		local latest = self._latest
		self._latest = Computed(self._internal_scope, function(use, scope)
			return processor(use(latest), use, scope)
		end)

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
		self._latest = ForPairs(self._internal_scope, self._latest, processor)

		return self
	end,
	for_values = function<S, IK, IV, OV>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForValuesProcessor<S, IV, OV>
	): Self<S, { [IK]: OV }>
		self._latest = ForValues(self._internal_scope, self._latest, processor)

		return self
	end,
	for_keys = function<S, IK, IV, OK>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForKeysProcessor<S, IK, OK>
	): Self<S, { [OK]: IV }>
		self._latest = ForKeys(self._internal_scope, self._latest, processor)

		return self
	end,

	resolve = function<T>(self: Self<unknown, T>): calc.UsedAs<T>
		return self._latest
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

local function Pipe<S, T>(scope: memory.Scope<S>, initial_value: calc.UsedAs<T>): pipeline.Pipe<S, T>
	local new_pipe: Self<S, T> = setmetatable({
		_internal_scope = inner_scope(scope),
		_latest = initial_value,
	}, METATABLE) :: any

	return new_pipe
end

return Pipe
