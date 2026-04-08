local memory = require("../../core_memory/types")

local SpecialKey = require("../SpecialKey")
local cleanup = require("../../core_memory/cleanup")

return SpecialKey(
	"observer",
	"OnRemoval",
	function(scope: memory.Scope, apply_to: Instance, removal_chore: memory.Chore)
		table.insert(
			scope,
			apply_to.AncestryChanged:Connect(function(_, parent: Instance?)
				if parent == nil then
					cleanup(removal_chore)
				end
			end)
		)
	end
)
