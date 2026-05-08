local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

export type ComputedProcessor<S, T> = (use: graph.use, scope: memory.Scope<S>) -> T
export type ComputedConstructor = <S, T>(
	scope: memory.Scope<S>,
	processor: ComputedProcessor<S, T>
) -> graph.usegetter<T>

export type ValueConstructor = <T>(scope: memory.Scope, initial_value: T) -> (graph.usegetter<T>, graph.setter<T>)

return {
	callback_error = "Error in callback:\nERROR_MESSAGE",
}
