local instances = require("../types")
local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

local function apply_attribute(
	scope: memory.Scope,
	apply_to: Instance,
	attribute: string,
	value: state.UsedAs<any>
)
	observe_immediate(scope, value, function()
		apply_to:SetAttribute(attribute, peek(value))
	end)
end

return {
	type = "SpecialKey",
	kind = "Attributes",
	stage = "self",
	apply = function(
		scope: memory.Scope,
		apply_to: Instance,
		attributes: { [string]: state.UsedAs<any> }
	)
		for attribute, value in attributes do
			apply_attribute(scope, apply_to, attribute, value)
		end
	end,
} :: instances.SpecialKey<"Attributes">
