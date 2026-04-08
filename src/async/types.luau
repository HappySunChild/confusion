local graph = require("../core_graph/types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type Eventual<T> = {
	kind: "Eventual",
	timeliness: "lazy",

	is_pending: (Eventual<T>) -> boolean,
} & state.StateNode<T>

export type EventualProcessor<S, T> = (
	use: state.Use,
	scope: memory.Scope<S>,
	become: (T) -> ()
) -> ()
export type EventualConstructor = <S, T>(
	scope: memory.Scope<S>,
	processor: EventualProcessor<S, T>,
	pending_value: T
) -> Eventual<T>

export type Await = (scope: memory.Scope, subject: graph.GraphNode) -> ()

return {
	invalid_await_type = "Invalid await type: expected a 'GraphNode' type, but got a '%s' type.",
}
