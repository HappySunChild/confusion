const memory = require("../../core_memory/types")
const rbx_instances = require("../types")
const state = require("../../core_state/types")

const cast_to_state = require("../../core_state/cast_to_state")
const observe = require("../../core_graph/observe")
const peek = require("../../core_use/peek")

const function apply_attribute(scope: memory.Scope, apply_to: Instance, attribute: string, value: state.UsedAs<any>)
	apply_to:SetAttribute(attribute, peek(value))

	if cast_to_state(value) ~= nil then
		observe(function()
			apply_to:SetAttribute(attribute, peek(value))
		end)
	end
end

return {
	type = "SpecialKey",
	kind = "Attributes",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: Instance, attributes: { [string]: state.UsedAs<any> })
		for attribute, value in attributes do
			apply_attribute(scope, apply_to, attribute, value)
		end
	end,
} :: rbx_instances.SpecialKey<"Attributes">
