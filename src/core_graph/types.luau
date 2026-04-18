local memory = require("../core_memory/types")

export type Validity =
	| "busy" -- currently reevaluating
	| "invalid" -- might need to be reevaluated
	| "dirty" -- definitely needs to be reevaluated
	| "valid" -- does not need to be reevaluated
export type Timeliness = "lazy" | "eager"

export type GraphNode = {
	scope: memory.Scope?,

	type: "graph",
	kind: string?,

	created_at: number,
	validity: Validity,
	timeliness: Timeliness,

	last_change: number?,
	last_compute: number?,
	users: { [GraphNode]: true }, -- aka dependentSet
	using: { [GraphNode]: true }, -- aka dependencySet
	_observers: { () -> () }?,

	_evaluate: (GraphNode) -> boolean,
	_oldest_task: () -> (),
}

export type Observe = (scope: memory.Scope, subject: any, callback: () -> ()) -> (() -> ())?

return {
	infinite_loop = "Detected an infinite loop. Consider adding an explicit breakpoint to your code to prevent a cyclic dependency.",

	cannot_depend_dependency_frozen = "The user '%s' cannot depend on '%s', because the latter is frozen.",
	cannot_depend_user_frozen = "The user '%s' cannot depend on '%s', because the former is frozen.",
}
