local instances = require("../roblox_instances/types")
local memory = require("../core_memory/types")

export type FromTemplateConstructor = <InstanceT>(
	scope: memory.Scope,
	template: InstanceT,
	properties: instances.Properties
) -> InstanceT

export type QueryDescendants = (
	scope: memory.Scope,
	selector: string,
	properties: instances.Properties
) -> (parent: Instance) -> Instance?

return {
	cannot_clone_template = "Unable to clone %s '%s'.",
	cannot_clone_template_unarchivable = "Unable to clone %s '%s.', because it's Archivable property is false.",
	missing_query_descendant = "Could not find descendants with query '%s'",
}
