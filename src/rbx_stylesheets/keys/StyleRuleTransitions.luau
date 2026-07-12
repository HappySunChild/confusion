const memory = require("../../core_memory/types")
const rbx_instances = require("../../rbx_instances/types")

return {
	type = "SpecialKey",
	kind = "StyleRuleTransitions",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: StyleRule, properties: { [string]: TweenInfo | string })
		apply_to:SetPropertyTransitions(properties)
	end,
} :: rbx_instances.SpecialKey<"StyleRyleTransitions">
