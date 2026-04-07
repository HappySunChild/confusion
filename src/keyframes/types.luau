local calc = require("../core_calc/types")
local memory = require("../core_memory/types")

export type Keyframes<T> = calc.StateNode<T> & {
	type: "State",
	kind: "Keyframes",
}
export type KeyframesConstructor = <T>(
	scope: memory.Scope,
	alpha: calc.UsedAs<number>,
	keyframes: { [number]: T }
) -> Keyframes<T>

return nil
