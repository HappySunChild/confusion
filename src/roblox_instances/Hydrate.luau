local instances = require("./types")
local memory = require("../core_memory/types")

local apply_properties = require("./apply_properties")

local function Hydrate<InstanceT>(
	scope: memory.Scope,
	instance: InstanceT,
	properties: instances.Properties
): InstanceT
	-- should we take accountability of destroying this object?
	table.insert(scope, instance)

	apply_properties(scope, instance, properties)

	return instance
end

return Hydrate
