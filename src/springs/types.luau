--!strict
const memory = require("../core_memory/types")
const state = require("../core_state/types")

export type Spring<T> = state.StateNode<T> & {
	set_position: (self: Spring<T>, new_position: T) -> (),
	set_velocity: (self: Spring<T>, new_velocity: T) -> (),
	add_velocity: (self: Spring<T>, delta: T) -> (),
}
export type SpringConstructor = <T>(
	scope: memory.Scope,
	goal: state.UsedAs<T>,
	speed: state.UsedAs<number>?,
	damping: state.UsedAs<number>?
) -> Spring<T>

return {
	unknown_packing_datatype = "Unable to pack value of unknown type '{type}'; returning nil.",
	unknown_unpacking_datatype = "Unable to unpack value of unknown type '{type}'; returning empty array.",
}
