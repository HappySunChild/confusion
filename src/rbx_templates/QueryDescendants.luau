const memory = require("../core_memory/types")
const rbx_instances = require("../rbx_instances/types")
const templates = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error_nonfatal = ExternalLogger.log_error_nonfatal

const apply_instance_properties = require("../rbx_instances/apply_instance_properties")

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
