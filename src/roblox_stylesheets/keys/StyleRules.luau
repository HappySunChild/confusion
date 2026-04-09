local instances = require("../../roblox_instances/types")

return {
	type = "SpecialKey",
	kind = "StyleRules",
	stage = "self",
	apply = function(_, apply_to: StyleBase, rules: { [number]: StyleRule })
		for priority, rule in rules do
			apply_to:InsertStyleRule(rule, priority)
		end
	end,
} :: instances.SpecialKey<"StyleRules">
