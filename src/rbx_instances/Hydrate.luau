const memory = require("../core_memory/types")
const rbx_instances = require("./types")

const Children = require("./keys/Children")
const apply_instance_properties = require("./apply_instance_properties")
const numerical_merge_into = require("./numerical_merge_into")

const function Hydrate<InstanceT>(scope: memory.Scope, instance: InstanceT, properties: rbx_instances.Properties): InstanceT
	-- should we take accountability of destroying this object?
	table.insert(scope, instance)

	numerical_merge_into(properties, Children)
	apply_instance_properties(scope, instance, properties)

	return instance
end

return Hydrate
