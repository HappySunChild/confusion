local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local KEY_CACHE = {}

local function AttributeChange(attribute: string): rbx_instances.SpecialKey<"AttributeChange">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "AttributeChange",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, callback: (any) -> ())
				local event = apply_to:GetAttributeChangedSignal(attribute)

				table.insert(
					scope,
					event:Connect(function()
						callback(apply_to:GetAttribute(attribute))
					end)
				)
			end,
		} :: rbx_instances.SpecialKey<"AttributeChange">

		KEY_CACHE[attribute] = key
	end

	return key
end

return AttributeChange
