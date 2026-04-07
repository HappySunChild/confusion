local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type Keyframes<T> = state.StateNode<T> & {
	type: "State",
	kind: "Keyframes",
}
export type KeyframesConstructor = <T>(
	scope: memory.Scope,
	alpha: state.UsedAs<number>,
	keyframes: { [number]: T }
) -> Keyframes<T>

return nil
