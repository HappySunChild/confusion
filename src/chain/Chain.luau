local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")
local pipeline = require("./types")
local state = require("../core_state/types")
local tweens = require("../motion_tweens/types")

local Computed = require("../core_state/Computed")
local ForKeys = require("../iter_for/ForKeys")
local ForPairs = require("../iter_for/ForPairs")
local ForValues = require("../iter_for/ForValues")
local Spring = require("../motion_springs/Spring")
local Tween = require("../motion_tweens/Tween")

local inner_scope = require("../core_memory/inner_scope")

type Self<S, T> = {
	scope: memory.Scope<S>,
} & pipeline.Chain<S, T>

local CLASS = table.freeze({
	type = "Chain",

	modify = function<S, T>(self: Self<S, T>, processor: (scope: memory.Scope<S>, latent: T) -> any): Self<S, T>
		self.latent = processor(self.scope, self.latent)
		return self
	end,

	map = function<S, T, O>(self: Self<S, T>, processor: (value: T, use: state.Use, scope: memory.Scope<S>) -> O): Self<S, O>
		local latent = self.latent
		self.latent = Computed(self.scope, function(use, scope)
			return processor(use(latent), use, scope)
		end)
		return self
	end,

	spring = function<S, T>(self: Self<S, T>, speed: state.UsedAs<number>?, damping: state.UsedAs<number>?): Self<S, T>
		self.latent = Spring(self.scope, self.latent, speed, damping)
		return self
	end,
	tween = function<S, T>(self: Self<S, T>, info: state.UsedAs<tweens.TweenInfo>): Self<S, T>
		self.latent = Tween(self.scope, self.latent, info)
		return self
	end,

	for_pairs = function<S, IK, IV, OK, OV>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForPairsProcessor<unknown, IK, IV, OK, OV>
	): Self<S, { [OK]: OV }>
		self.latent = ForPairs(self.scope, self.latent, processor)
		return self
	end,
	for_values = function<S, IK, IV, OV>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForValuesProcessor<S, IV, OV>
	): Self<S, { [IK]: OV }>
		self.latent = ForValues(self.scope, self.latent, processor)
		return self
	end,
	for_keys = function<S, IK, IV, OK>(
		self: Self<S, { [IK]: IV }>,
		processor: iter_for.ForKeysProcessor<S, IK, OK>
	): Self<S, { [OK]: IV }>
		self.latent = ForKeys(self.scope, self.latent, processor)
		return self
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Chain<S, T>(scope: memory.Scope<S>, initial_value: state.UsedAs<T>): pipeline.Chain<S, T>
	local new_chain: Self<S, T> = setmetatable({
		scope = inner_scope(scope),
		latent = initial_value,
	}, CLASS_METATABLE) :: any

	return new_chain
end

return Chain
