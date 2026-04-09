local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local SpecialKey = require("../../roblox_instances/SpecialKey")
local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

local StyleProperties = SpecialKey(
	"self",
	"StyleProperties",
	function(scope: memory.Scope, apply_to: StyleRule, properties: { [string]: state.UsedAs<any> })
		for property, value in properties do
			observe_immediate(scope, value, function()
				apply_to:SetProperty(property, peek(value))
			end)
		end
	end
)

return StyleProperties
