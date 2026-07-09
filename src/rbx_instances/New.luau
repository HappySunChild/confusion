const memory = require("../core_memory/types")
const rbx_instances = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const Children = require("./keys/Children")
const apply_instance_properties = require("./apply_instance_properties")
const implicit_numerical_merge = require("./implicit_numerical_merge")

const function New(scope: memory.Scope, class_name: string, properties: rbx_instances.Properties): Instance
	const ok, new_instance = pcall(Instance.new, class_name)

	if not ok then
		log_error(rbx_instances.cannot_create_class, nil, class_name)
	end

	table.insert(scope, new_instance)

	-- this directly modifies the properties table, which I think is ok.
	-- if the side effects of this are unacceptable then we switch to a non mutating variant.
	implicit_numerical_merge(properties, Children)
	apply_instance_properties(scope, new_instance, properties)

	return new_instance
end

return New
