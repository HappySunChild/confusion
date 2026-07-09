const memory = require("../core_memory/types")
const rbx_instances = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const apply_instance_properties = require("./apply_instance_properties")
const implicit_numerical_merge = require("./implicit_numerical_merge")

const function from_description(
	scope: memory.Scope,
	description: rbx_instances.ChildDescription,
	implicit_numerical_merge_key: any
): Instance
	const class_name = table.remove(description, 1)
	const ok, new_instance = pcall(Instance.new, class_name)

	if not ok then
		log_error(rbx_instances.cannot_create_class, nil, class_name)
	end

	table.insert(scope, new_instance)

	implicit_numerical_merge(description, implicit_numerical_merge_key)
	apply_instance_properties(scope, new_instance, description)

	return new_instance
end

return from_description
