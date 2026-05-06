local graph = require("../../core_graph/types")
local memory = require("../../core_memory/types")
local rbx_instances = require("../../roblox_instances/types")

local Observer = require("../../core_graph/Observer")

return {
	type = "SpecialKey",
	kind = "StyleRuleProperties",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: StyleRule, properties: { [string]: graph.UsedAs<any> })
		for property, value in properties do
			if type(value) == "function" then
				Observer(scope, function(use: graph.use)
					apply_to:SetProperty(property, use(value))
				end)
			else
				apply_to:SetProperty(property, value)
			end
		end
	end,
} :: rbx_instances.SpecialKey<"StyleRuleProperties">
