const memory = require("../core_memory/types")
const rbx_instances = require("../roblox_instances/types")
const templates = require("../roblox_templates/types")

const apply_instance_properties = require("../roblox_instances/apply_instance_properties")
const log_error_nonfatal = require("../core_logging/log_error_nonfatal")

const function QueryDescendants(scope: memory.Scope, selector: string, properties: rbx_instances.Properties)
	return function(parent: Instance): Instance?
		const descendants = parent:QueryDescendants(selector)
		const child = descendants[1]

		if child == nil then
			log_error_nonfatal(templates.missing_query_descendant, nil, selector)

			return nil
		end

		apply_instance_properties(scope, child, properties)

		return child
	end
end

return QueryDescendants
