local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")
local tweens = require("../motion_tweens/types")

export type Chain<S, T> = {
	type: "Chain",

	latent: T,

	map: <O>(Chain<S, T>, processor: (value: T, use: state.Use, scope: memory.Scope<S>) -> O) -> Chain<S, T>,
	modify: <O>(Chain<S, T>, processor: (scope: memory.Scope<S>, latent: T) -> O) -> Chain<S, T>,

	spring: (Chain<S, T>, speed: state.UsedAs<number>?, damping: state.UsedAs<number>?) -> Chain<S, T>,
	tween: (Chain<S, T>, info: state.UsedAs<tweens.TweenInfo>) -> Chain<S, T>,

	for_pairs: <IK, IV, OK, OV>(
		Chain<S, T>,
		processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
	) -> Chain<S, T>,
	for_values: <IK, IV, OV>(Chain<S, T>, processor: iter_for.ForValuesProcessor<S, IV, OV>) -> Chain<S, T>,
	for_keys: <IK, IV, OK>(Chain<S, T>, processor: iter_for.ForKeysProcessor<S, IK, OK>) -> Chain<S, T>,
}

export type ChainConstructor = <S, T>(scope: memory.Scope<S>, initial_value: T) -> Chain<S, T>

return nil
