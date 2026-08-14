--!strict

const memory = require("../core_memory/types")
const state = require("../core_state/types")

export type SpecialKeyStage = | "self" | "descendants" | "properties" | "ancestor" | "observer" | "last"

export type SpecialKey<T = string> = {
	type: "SpecialKey",
	kind: T,
	stage: SpecialKeyStage,
	apply: (scope: memory.Scope, instance: Instance, value: unknown) -> (),
}

export type ChildState = state.StateNode<Child>
export type ChildUnresolved = (parent: Instance) -> Child?
export type ChildMany = { Child }
export type Child = Instance | ChildState | ChildUnresolved | ChildMany

export type Properties = { [string | number | SpecialKey]: any }
export type Tag = string | { Tag } | state.StateNode<Tag>

export type NewConstructor = (scope: memory.Scope, class_name: string, properties: Properties?) -> Instance
export type HydrateConstructor = <InstanceT>(
	scope: memory.Scope,
	instance: InstanceT,
	properties: Properties
) -> InstanceT

return {
	cannot_create_class = "Unable to create instance of type '{class}'.",
	cannot_connect_change = "The {class} class doesn't have a property called '{property}'.",
	cannot_connect_event = "The {class} class doesn't have a event called '{event}'.",

	property_cannot_assign = "The {class} class has no assignable property '{property}'.",
	property_assign_error = "An error occured while setting property '{class}.{property}' to {value}:\nERROR_MESSAGE",

	invalid_key_type = "Invalid key type: expected a 'string | SpecialKey' type, but got a '{given_type}' type.",
	invalid_child_type = "Invalid child type: expected a 'Instance | (Instance) -> [RECURSE] | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '{given_type}' type.",
	invalid_tag_type = "Invalid tag type: expected a 'string | { [RECURSE] } | StateNode<[RECURSE]>' type, but got a '{given_type}' type.",
	invalid_ref_type = "Invalid ref type: expected a 'Value' type, but got a '{given_type}' type.",
	invalid_out_type = "Invalid out type: expected a 'Value' type, but got a '{given_type}' type.",
	invalid_property_type = "'{class}.{property}' expected a '{expected_type}' type, but got a '{given_type}' type.",

	missing_specialkey_stage = "The SpecialKey '{kind}' is missing a stage property.",
	invalid_specialkey_stage = "The SpecialKey '{kind}' has an invalid stage '{stage}'.",
	specialkey_apply_error = "The SpecialKey '{kind}' (@{stage}) errored while being applied to {instance_class} '{instance_name}':\nERROR_MESSAGE",
}
