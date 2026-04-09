local instances = require("../types")
local memory = require("../../core_memory/types")
local state = require("../../core_state/types")

local log_error = require("../../core_logging/log_error")
local xtypeof = require("../../core_graph/xtypeof")

local KEY_CACHE = {}

local function AttributeOut(attribute: string): instances.SpecialKey<"AttributeOut">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "AttributeOut",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, value: state.Value<any>)
				if xtypeof(value) ~= "State" or value.Kind ~= "Value" then
					log_error(instances.invalid_out_type, nil, typeof(value))
				end

				local event = apply_to:GetAttributeChangedSignal(attribute)

				table.insert(
					scope,
					event:Connect(function()
						value:set(apply_to:GetAttribute(attribute))
					end)
				)

				return
			end,
		} :: instances.SpecialKey<"AttributeOut">

		KEY_CACHE[attribute] = key
	end

	return key
end

return AttributeOut
