local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local apply_properties = require("./apply_properties")
local log_error = require("../core_logging/log_error")

local function New(
	scope: memory.Scope,
	class_name: string,
	properties: rbx_instances.Properties
): Instance
	local success, new_instance = pcall(Instance.new, class_name, nil) -- ok

	if not success then
		log_error(rbx_instances.cannot_create_class, nil, class_name)
	end

	table.insert(scope, new_instance)

	apply_properties(scope, new_instance, properties)

	return new_instance
end

return New
