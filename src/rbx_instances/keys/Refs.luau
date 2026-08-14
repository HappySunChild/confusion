--!strict
--!native
--!optimize 2

const rbx_instances = require("../types")
const state = require("../../core_state/types")

const ExternalLogger = require("../../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const xtypeof = require("../../core_graph/xtypeof")

type OneOrMore<T> = T | { T }

const function process_ref(instance: Instance, ref: OneOrMore<state.Value<Instance>>)
	const ref_type = xtypeof(ref)

	if ref_type == "state" and ((ref :: any) :: state.Value<Instance>).kind == "Value" then
		ref = (ref :: any) :: state.Value<Instance>
		ref:set(instance)
	elseif ref_type == "table" then
		for _, sub_ref in ref do
			process_ref(instance, sub_ref)
		end
	else
		log_error(rbx_instances.invalid_ref_type, nil, { given_type = ref_type })
	end
end

return {
	type = "SpecialKey",
	kind = "Refs",
	stage = "self",
	apply = function(scope, apply_to: Instance, root_ref: OneOrMore<state.Value<Instance>>)
		process_ref(apply_to, root_ref)
	end,
}
