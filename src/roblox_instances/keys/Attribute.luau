local memory = require("../../core_memory/types")
local rbx_instances = require("../types")
local state = require("../../core_state/types")

local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

local KEY_CACHE = {}

local function Attribute(attribute: string): rbx_instances.SpecialKey<"Attribute">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "Attribute",
			stage = "self",
			apply = function(scope: memory.Scope, apply_to: Instance, value: state.UsedAs<any>)
				observe_immediate(scope, value, function()
					apply_to:SetAttribute(attribute, peek(value))
				end)
			end,
		} :: rbx_instances.SpecialKey<"Attribute">

		KEY_CACHE[attribute] = key
	end

	return key
end

return Attribute
