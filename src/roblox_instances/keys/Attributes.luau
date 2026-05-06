local graph = require("../../core_graph/types")
local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local Observer = require("../../core_graph/Observer")
local peek = require("../../core_use/peek")

local function apply_attribute(scope: memory.Scope, apply_to: Instance, attribute: string, value: graph.UsedAs<any>)
	if type(value) == "function" then
		Observer(scope, function(use: graph.use)
			apply_to:SetAttribute(attribute, use(value))
		end)
	else
		apply_to:SetAttribute(attribute, peek(value))
	end
end

return {
	type = "SpecialKey",
	kind = "Attributes",
	stage = "self",
	apply = function(scope: memory.Scope, apply_to: Instance, attributes: { [string]: graph.UsedAs<any> })
		for attribute, value in attributes do
			apply_attribute(scope, apply_to, attribute, value)
		end
	end,
} :: rbx_instances.SpecialKey<"Attributes">
