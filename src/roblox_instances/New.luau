local memory = require("../core_memory/types")
local rbx_instances = require("./types")

local Children = require("./keys/Children")
local apply_instance_properties = require("./apply_instance_properties")
local implicit_merge = require("./implicit_merge")
local log_error = require("../core_logging/log_error")

local function New(scope: memory.Scope, class_name: string, properties: rbx_instances.Properties): Instance
	local ok, new_instance = pcall(Instance.new, class_name, nil) -- ok

	if not ok then
		log_error(rbx_instances.cannot_create_class, nil, class_name)
	end

	table.insert(scope, new_instance)

	-- this directly modifies the properties table, which I think is ok.
	-- if the side effects of this are unacceptable then we switch to a non mutating variant.
	implicit_merge(properties, Children)
	apply_instance_properties(scope, new_instance, properties)

	return new_instance
end

return New
