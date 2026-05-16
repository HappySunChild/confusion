const memory = require("../../core_memory/types")
const rbx_instances = require("../../roblox_instances/types")
const state = require("../../core_state/types")

const apply_instance_properties = require("../../roblox_instances/apply_instance_properties")

return {
	type = "SpecialKey",
	kind = "StyleLink",
	stage = "descendants",
	apply = function(scope: memory.Scope, apply_to: Instance, style: state.UsedAs<StyleSheet>)
		const link = Instance.new("StyleLink")

		apply_instance_properties(scope, link, {
			Parent = apply_to,
			StyleSheet = style,
		})

		table.insert(scope, link)
	end,
} :: rbx_instances.SpecialKey<"StyleLink">
