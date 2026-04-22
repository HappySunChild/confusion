local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local apply_instance_properties = require("./apply_instance_properties")
local implicit_merge = require("./implicit_merge")
local log_error = require("../core_logging/log_error")

local function from_description(
	scope: memory.Scope,
	description: rbx_instances.ChildDescription,
	implicit_merge_key: any
): Instance
	local class_name = table.remove(description, 1)
	local ok, new_instance = pcall(Instance.new, class_name, nil)

	if not ok then
		log_error(rbx_instances.cannot_create_class, nil, class_name)
	end

	table.insert(scope, new_instance)

	implicit_merge(description, implicit_merge_key)
	apply_instance_properties(scope, new_instance, description)

	return new_instance
end

return from_description
