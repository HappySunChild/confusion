local graph = require("../../core_graph/types")
local rbx_instances = require("../types")

local log_error = require("../../core_logging/log_error")

type OneOrMore<T> = T | { T }

local function process_ref(instance: Instance, ref: OneOrMore<graph.setter<Instance>>)
	local ref_type = type(ref)

	if ref_type == "function" then
		ref(instance)

		return
	elseif ref_type == "table" then
		for _, sub_ref in ref do
			process_ref(sub_ref, instance)
		end

		return
	end

	log_error(rbx_instances.invalid_ref_type, nil, ref_type)
end

return {
	type = "SpecialKey",
	kind = "Refs",
	stage = "self",
	apply = function(scope, apply_to: Instance, root_ref: OneOrMore<graph.setter<Instance>>)
		process_ref(apply_to, root_ref)
	end,
}
