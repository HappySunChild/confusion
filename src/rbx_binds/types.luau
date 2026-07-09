local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type PropertyOf<T> = { kind: "PropertyOf" } & state.StateNode<T>
export type AttributeOf<T> = { kind: "AttributeOf" } & state.StateNode<T>

export type PropertyOfConstructor = (
	scope: memory.Scope,
	instance: Instance,
	property: string
) -> PropertyOf<unknown>
export type AttributeOfConstructor = (
	scope: memory.Scope,
	instance: Instance,
	attribute: string
) -> AttributeOf<unknown>

return nil
