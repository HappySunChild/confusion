local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")
local tweens = require("../motion_tweens/types")

export type Pipe<S, T> = {
	type: "Pipe",

	resolve: (Pipe<S, T>) -> state.UsedAs<T>,

	map: (Pipe<S, T>, processor: (value: T, use: state.Use, scope: memory.Scope<S>) -> any) -> Pipe<S, T>,
	modify: (Pipe<S, T>, processor: (latest: T, scope: memory.Scope<S>) -> any) -> Pipe<S, T>,

	spring: (Pipe<S, T>, speed: state.UsedAs<number>?, damping: state.UsedAs<number>?) -> Pipe<S, T>,
	tween: (Pipe<S, T>, info: state.UsedAs<tweens.TweenInfo>) -> Pipe<S, T>,

	for_pairs: <IK, IV, OK, OV>(
		Pipe<S, T>,
		processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
	) -> Pipe<S, T>,
	for_values: <IK, IV, OV>(Pipe<S, T>, processor: iter_for.ForValuesProcessor<S, IV, OV>) -> Pipe<S, T>,
	for_keys: <IK, IV, OK>(Pipe<S, T>, processor: iter_for.ForKeysProcessor<S, IK, OK>) -> Pipe<S, T>,
}

export type PipeConstructor = <S, T>(scope: memory.Scope<S>, initial_value: T) -> Pipe<S, T>

return nil
