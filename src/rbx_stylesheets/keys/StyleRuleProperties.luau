const memory = require("../../core_memory/types")
const rbx_instances = require("../../rbx_instances/types")
const state = require("../../core_state/types")

const cast_to_state = require("../../core_state/cast_to_state")
const observe = require("../../core_graph/observe")
const peek = require("../../core_use/peek")

return {
	type = "SpecialKey",
	kind = "StyleRuleProperties",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: StyleRule, properties: { [string]: state.UsedAs<any> })
		for property, value in properties do
			apply_to:SetProperty(property, peek(value))

			if cast_to_state(value) ~= nil then
				observe(scope, value, function()
					apply_to:SetProperty(property)
				end)
			end
		end
	end,
} :: rbx_instances.SpecialKey<"StyleRuleProperties">
