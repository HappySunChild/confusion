local instances = require("../types")
local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local SpecialKey = require("../SpecialKey")
local observe_immediate = require("../../core_graph/observe_immediate")
local peek = require("../../core_use/peek")

local KEY_CACHE = {}

local function Attribute(attribute: string): instances.SpecialKey<"Attribute">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = SpecialKey(
			"self",
			"Attribute",
			function(scope: memory.Scope, apply_to: Instance, value: state.UsedAs<any>)
				observe_immediate(scope, value, function()
					apply_to:SetAttribute(attribute, peek(value))
				end)
			end
		)

		KEY_CACHE[attribute] = key
	end

	return key
end

return Attribute
