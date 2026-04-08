local instances = require("../roblox_instances/types")
local memory = require("../core_memory/types")
local templates = require("../roblox_templates/types")

local apply_properties = require("../roblox_instances/apply_properties")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")

local function QueryDescendants(
	scope: memory.Scope,
	selector: string,
	properties: instances.Properties
)
	return function(parent: Instance): Instance?
		local descendants = parent:QueryDescendants(selector)
		local child = descendants[1]

		if child == nil then
			log_error_nonfatal(templates.missing_query_descendant, nil, selector)

			return nil
		end

		apply_properties(scope, child, properties)

		return child
	end
end

return QueryDescendants
