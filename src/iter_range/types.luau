--!strict
--!native
--!optimize 2

const iter = require("../iter/types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

export type RangePair<T> = {
	input_index: number,
} & state.StateNode<T?>

export type RangeDisassemblyProcessor<S, T> = (use: state.Use, scope: memory.Scope<S>, index: number) -> T
export type ForRangeConstructor = <S, T>(
	scope: memory.Scope<S>,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	processor: RangeDisassemblyProcessor<S, T>,
	step: state.UsedAs<number>?
) -> iter.Iter<number, T>

return nil
