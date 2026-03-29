local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

export type StateNode<T> = {
	type: "State",
	_cached_value: T,
} & graph.GraphNode

export type UsedAs<T> = StateNode<T> | T
export type Use = <T>(x: UsedAs<T>) -> T

-- A state object whose value can be set by the user at any time.
export type Value<T> = {
	kind: "Value",
	timeliness: "lazy",

	set: (Value<T>, new_value: T) -> T,
	update: (Value<T>, predicate: (T) -> T) -> T,
} & StateNode<T>
export type ValueConstructor = <T>(scope: memory.Scope, initial_value: T) -> Value<T>

-- A state object whose value is derived from other objects using a callback.
export type Computed<T> = {
	kind: "Computed",
	timeliness: "eager",
} & StateNode<T>

export type ComputedProcessor<S, T> = (use: Use, scope: memory.Scope<S>) -> T
export type ComputedConstructor = <S, T>(
	scope: memory.Scope<S>,
	processor: ComputedProcessor<S, T>
) -> Computed<T> | T

return {
	callback_error = "Error in callback:\nERROR_MESSAGE",
}
