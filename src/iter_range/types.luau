local iter = require("../iter/types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type Range = {
	kind: "Range",
	timeliness: "lazy",
} & state.StateNode<{ number }>
export type RangeConstructor = (
	scope: memory.Scope,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	step: state.UsedAs<number>?
) -> Range | { number }

export type RangePair<T> = {
	invalidate_index: (RangePair<T>, new_index: number) -> (),
} & state.StateNode<T>

export type RangeDisassemblyProcessor<S, T> = (
	use: state.Use,
	scope: memory.Scope<S>,
	index: number
) -> T
export type ForRangeConstructor = <S, T>(
	scope: memory.Scope<S>,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	processor: RangeDisassemblyProcessor<S, T>,
	step: state.UsedAs<number>?
) -> iter.Iter<number, T>

return nil
