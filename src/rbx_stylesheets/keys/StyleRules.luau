const memory = require("../../core_memory/types")
const rbx_instances = require("../../rbx_instances/types")

return {
	type = "SpecialKey",
	kind = "StyleRules",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: StyleBase, rules: { StyleRule })
		apply_to:SetStyleRules(rules)
	end,
} :: rbx_instances.SpecialKey<"StyleRules">
