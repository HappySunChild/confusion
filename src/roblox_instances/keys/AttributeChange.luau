local instances = require("../types")
local memory = require("../../core_memory/types")

local SpecialKey = require("../SpecialKey")

local KEY_CACHE = {}

local function AttributeChange(attribute: string): instances.SpecialKey<"AttributeChange">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = SpecialKey(
			"observer",
			"AttributeChanged",
			function(scope: memory.Scope, apply_to: Instance, callback: (any) -> ())
				local event = apply_to:GetAttributeChangedSignal(attribute)

				table.insert(
					scope,
					event:Connect(function()
						callback(apply_to:GetAttribute(attribute))
					end)
				)
			end
		)

		KEY_CACHE[attribute] = key
	end

	return key
end

return AttributeChange
