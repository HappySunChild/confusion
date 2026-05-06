local graph = require("../../core_graph/types")
local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local log_error = require("../../core_logging/log_error")

local KEY_CACHE = {}

local function AttributeOut(attribute: string): rbx_instances.SpecialKey<"AttributeOut">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "AttributeOut",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, set_value: graph.setter<any>)
				-- if xtypeof(set_value) ~= "state" or set_value.Kind ~= "Value" then
				-- 	log_error(rbx_instances.invalid_out_type, nil, typeof(set_value))
				-- end
				if type(set_value) ~= "function" then
					log_error(rbx_instances.invalid_out_type, nil, type(set_value))
				end

				local event = apply_to:GetAttributeChangedSignal(attribute)

				table.insert(
					scope,
					event:Connect(function()
						set_value(apply_to:GetAttribute(attribute))
					end)
				)

				return
			end,
		} :: rbx_instances.SpecialKey<"AttributeOut">

		KEY_CACHE[attribute] = key
	end

	return key
end

return AttributeOut
