local calc = require("../core_calc/types")
local iter_for = require("../iter_for/types")
local memory = require("../core_memory/types")
local tweens = require("../motion_tweens/types")

export type Pipe<S, T> = {
	type: "Pipe",

	spring: (
		Pipe<S, T>,
		speed: calc.UsedAs<number>?,
		damping: calc.UsedAs<number>?
	) -> Pipe<S, T>,
	tween: (Pipe<S, T>, info: calc.UsedAs<tweens.TweenInfo>) -> Pipe<S, T>,

	map: <O>(
		Pipe<S, T>,
		processor: (value: T, use: calc.Use, scope: memory.Scope<S>) -> O
	) -> Pipe<S, T>, -- Pipe<O>, -- this isn't allowed?

	for_pairs: <IK, IV, OK, OV>(
		Pipe<S, T>,
		processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
	) -> Pipe<S, T>, -- Pipe<{ [OK]: OV }>,
	for_values: <IK, IV, OV>(
		Pipe<S, T>,
		processor: iter_for.ForValuesProcessor<S, IV, OV>
	) -> Pipe<S, T>, -- Pipe<{ [IK]: OV }>,
	for_keys: <IK, IV, OK>(
		Pipe<S, T>,
		processor: iter_for.ForKeysProcessor<S, IK, OK>
	) -> Pipe<S, T>, -- Pipe<{ [OK]: IV }>,

	resolve: (Pipe<S, T>) -> calc.UsedAs<T>,
}

export type PipeConstructor = <S, T>(
	scope: memory.Scope<S>,
	initial_value: calc.UsedAs<T>
) -> Pipe<S, T>

return nil
