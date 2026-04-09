local instances = require("../types")
local memory = require("../../core_memory/types")

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
} :: instances.SpecialKey<"OnRemoval">
