--!strict

const graph = require("../core_graph/types")
const memory = require("../core_memory/types")

export type StateNode<T> = {
	cached_value: T,
} & graph.GraphNode

export type UsedAs<T> = StateNode<T> | T
export type Use = <T>(UsedAs<T>) -> T
export type Flatten = <T>(use: Use, x: UsedAs<T>) -> T

--- A state object whose value can be set by the user at any time.
export type Value<T> = {
	set: (Value<T>, new_value: T) -> T,
	update: (Value<T>, predicate: (T) -> T) -> T,
} & StateNode<T>
export type ValueConstructor = <T>(scope: memory.Scope, initial_value: T) -> Value<T>

--- A state object whose value is derived from other objects using a callback.
export type Computed<T> = StateNode<T>

export type ComputedProcessor<S, T> = (use: Use, scope: memory.Scope<S>) -> T
export type ComputedConstructor = <S, T>(scope: memory.Scope<S>, processor: ComputedProcessor<S, T>) -> Computed<T>

return {
	callback_error = "Error in callback:\nERROR_MESSAGE",
	invalid_user = "Unnable to create `use` callback for non-state user; got a value of type '{type}' ({value})",
}
