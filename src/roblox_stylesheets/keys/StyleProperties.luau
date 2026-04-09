local instances = require("../../roblox_instances/types")
local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

return {
	type = "SpecialKey",
	kind = "StyleProperties",
	stage = "self",
	apply = function(
		scope: memory.Scope,
		apply_to: StyleRule,
		properties: { [string]: state.UsedAs<any> }
	)
		for property, value in properties do
			observe_immediate(scope, value, function()
				apply_to:SetProperty(property, peek(value))
			end)
		end
	end,
} :: instances.SpecialKey<"StyleProperties">
