const memory = require("../../core_memory/types")
const rbx_instances = require("../types")
const state = require("../../core_state/types")

const log_warn = require("../../core_logging/log_warn")
const observe_immediate = require("../../core_graph/observe_immediate")
const peek = require("../../core_use/peek")

const function set_parent(instance: Instance, parent: Instance?)
	const success, err = pcall(function()
		instance.Parent = parent
	end)

	if not success then
		log_warn(err)
	end
end

return {
	type = "SpecialKey",
	kind = "Parent",
	stage = "ancestor",
	apply = function(scope: memory.Scope, apply_to: Instance, parent: state.UsedAs<Instance?>)
		observe_immediate(scope, parent, function()
			set_parent(apply_to, peek(parent))
		end)
	end,
} :: rbx_instances.SpecialKey<"Parent">
