local graph = require("../../core_graph/types")
local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local log_error = require("../../core_logging/log_error")

local KEY_CACHE = {}

local function Out(property: string): rbx_instances.SpecialKey<"Out">
	local key = KEY_CACHE[property]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "Out",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, set_value: graph.setter<any>)
				if type(set_value) ~= "function" then
					log_error(rbx_instances.invalid_out_type, nil, type(set_value))
				end

				local event = apply_to:GetPropertyChangedSignal(property)

				table.insert(
					scope,
					event:Connect(function()
						set_value(apply_to[property])
					end)
				)
			end,
		} :: rbx_instances.SpecialKey<"Out">

		KEY_CACHE[property] = key
	end

	return key
end

return Out
