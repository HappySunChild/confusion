const iter_for = require("../iter_for/types")
const memory = require("../core_memory/types")
const pipeline = require("./types")
const state = require("../core_state/types")
const tweens = require("../motion_tweens/types")

const Computed = require("../core_state/Computed")
const ForKeys = require("../iter_for/ForKeys")
const ForPairs = require("../iter_for/ForPairs")
const ForValues = require("../iter_for/ForValues")
const Spring = require("../motion_springs/Spring")
const Tween = require("../motion_tweens/Tween")

const inner_scope = require("../core_memory/inner_scope")

type Self<S, T> = {
	scope: memory.Scope<S>,
} & pipeline.Chain<S, T>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "Chain",

		modify = function<S, T>(self: Self<S, T>, processor: (scope: memory.Scope<S>, latent: T) -> any): Self<S, T>
			self.latent = processor(self.scope, self.latent)
			return self
		end,

		map = function<S, T, O>(
			self: Self<S, T>,
			processor: (value: T, use: state.Use, scope: memory.Scope<S>) -> O
		): Self<S, O>
			const latent = self.latent
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
	}),
})

const function Chain<S, T>(scope: memory.Scope<S>, initial_value: state.UsedAs<T>): pipeline.Chain<S, T>
	const new_chain: Self<S, T> = setmetatable({
		scope = inner_scope(scope),
		latent = initial_value,
	}, CLASS_MT) :: any

	return new_chain
end

return Chain
