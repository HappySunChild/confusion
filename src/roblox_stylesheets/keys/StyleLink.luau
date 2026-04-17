local memory = require("../../core_memory/types")
local rbx_instances = require("../../roblox_instances/types")
local state = require("../../core_state/types")

local apply_instance_properties = require("../../roblox_instances/apply_instance_properties")

return {
	type = "SpecialKey",
	kind = "StyleLink",
	stage = "descendants",
	apply = function(scope: memory.Scope, apply_to: Instance, style: state.UsedAs<StyleSheet>)
		local link = Instance.new("StyleLink")

		apply_instance_properties(scope, link, {
			Parent = apply_to,
			StyleSheet = style,
		})

		table.insert(scope, link)
	end,
} :: rbx_instances.SpecialKey<"StyleLink">
