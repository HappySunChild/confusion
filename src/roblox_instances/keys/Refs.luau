local instances = require("../types")
local state = require("../../core_state/types")

local log_error = require("../../core_logging/log_error")
local xtypeof = require("../../core_graph/xtypeof")

type OneOrMore<T> = T | { T }

local function process_ref(instance: Instance, ref: OneOrMore<state.Value<Instance>>)
	local ref_type = xtypeof(ref)

	if ref_type == "state" and ref.kind == "Value" then
		ref = ref :: state.Value<Instance>
		ref:set(instance)

		return
	elseif ref_type == "table" then
		for _, sub_ref in ref do
			process_ref(sub_ref, instance)
		end

		return
	end

	log_error(instances.invalid_ref_type, nil, ref_type)
end

return {
	type = "SpecialKey",
	kind = "Refs",
	stage = "self",
	apply = function(scope, apply_to: Instance, root_ref: OneOrMore<state.Value<Instance>>)
		process_ref(apply_to, root_ref)
	end,
}
