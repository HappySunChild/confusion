local calc = require("../../core-calc/types")
local memory = require("../../core-memory/types")

local SpecialKey = require("../../roblox-instances/SpecialKey")
local observe_immediate = require("../../core-graph/observe_immediate")
local peek = require("../../core-use/peek")

local StyleProperties = SpecialKey(
	"self",
	"StyleProperties",
	function(scope: memory.Scope, apply_to: StyleRule, properties: { [string]: calc.UsedAs<any> })
		for property, value in properties do
			observe_immediate(scope, value, function()
				apply_to:SetProperty(property, peek(value))
			end)
		end
	end
)

return StyleProperties
