local instances = require("../../roblox_instances/types")

return {
	type = "SpecialKey",
	kind = "StyleDerives",
	stage = "self",
	apply = function(_, apply_to: StyleSheet, derives: { StyleSheet })
		apply_to:SetDerives(derives)
	end,
} :: instances.SpecialKey<"StyleDerives">
