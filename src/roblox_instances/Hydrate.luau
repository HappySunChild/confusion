local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local apply_instance_properties = require("./apply_instance_properties")

local function Hydrate<InstanceT>(scope: memory.Scope, instance: InstanceT, properties: rbx_instances.Properties): InstanceT
	-- should we take accountability of destroying this object?
	table.insert(scope, instance)

	apply_instance_properties(scope, instance, properties)

	return instance
end

return Hydrate
