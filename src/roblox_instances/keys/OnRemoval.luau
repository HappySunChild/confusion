local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local cleanup = require("../../core_memory/cleanup")

return {
	type = "SpecialKey",
	kind = "OnRemoval",
	stage = "observer",
	apply = function(scope: memory.Scope, apply_to: Instance, removal_chore: any)
		table.insert(
			scope,
			apply_to.AncestryChanged:Connect(function(_, parent: Instance?)
				if parent == nil then
					cleanup(removal_chore)
				end
			end)
		)
	end,
} :: rbx_instances.SpecialKey<"OnRemoval">
