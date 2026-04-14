local instances = require("../../roblox_instances/types")
local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local cast_to_state = require("../../core_state/cast_to_state")
local observe = require("../../core_graph/observe")
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
			apply_to:SetProperty(property, peek(value))

			if cast_to_state(value) ~= nil then
				observe(scope, value, function()
					apply_to:SetProperty(property)
				end)
			end
		end
	end,
} :: instances.SpecialKey<"StyleProperties">
