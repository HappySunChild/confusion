local memory = require("../core_memory/types")
local state = require("../core_state/types")

export type SpecialKeyStage = | "self" | "descendants" | "properties" | "ancestor" | "observer" | "last"

export type SpecialKey<T = string> = {
	type: "SpecialKey",
	kind: T,
	stage: SpecialKeyStage,
	apply: (scope: memory.Scope, instance: Instance, value: unknown) -> (),
}

export type Properties = { [any]: any }
export type Child = Instance | ((Instance) -> Child?) | { Child } | state.StateNode<Child>
export type Tag = string | { Tag } | state.StateNode<Tag>

export type NewConstructor = (scope: memory.Scope, class_name: string, properties: Properties) -> Instance
export type HydrateConstructor = <InstanceT>(
	scope: memory.Scope,
	instance: InstanceT,
	properties: Properties
) -> InstanceT

return {
	cannot_create_class = "Unable to create instance of type '%s'.",
	cannot_connect_change = "The %s class doesn't have a property called '%s'.",
	cannot_connect_event = "The %s class doesn't have a event called '%s'.",

	property_cannot_assign = "The %s class has no assignable property '%s'.",
	property_assign_error = "Error while setting property:\nERROR_MESSAGE",

	invalid_key_type = "Invalid key type: expected a 'string | SpecialKey' type, but got a '%s' type.",
	invalid_child_type = "Invalid child type: expected a 'Instance | (Instance) -> [RECURSE] | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '%s' type.",
	invalid_tag_type = "Invalid tag type: expected a 'string | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '%s' type.",
	invalid_ref_type = "Invalid ref type: expected a 'Value' type, but got a '%s' type.",
	invalid_out_type = "Invalid out type: expected a 'Value' type, but got a '%s' type.",
	invalid_property_type = "'%s.%s' expected a '%s' type, but got a '%s' type.",

	missing_specialkey_stage = "The SpecialKey '%s' is missing a stage property.",
	invalid_specialkey_stage = "The SpecialKey '%s' has an invalid stage '%s'.",
	specialkey_apply_error = "The SpecialKey '%s' errored while being applied to %s '%s' with value %* at stage '%s':\nERROR_MESSAGE",
}
