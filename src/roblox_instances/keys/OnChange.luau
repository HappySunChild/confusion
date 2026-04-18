local memory = require("../../core_memory/types")
local rbx_instances = require("../types")

local log_error = require("../../core_logging/log_error")

local KEY_CACHE = {}

local function OnChange(property: string): rbx_instances.SpecialKey<"OnChange">
	local key = KEY_CACHE[property]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "OnChange",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, callback: (any) -> ())
				local ok, event = pcall(apply_to.GetPropertyChangedSignal, apply_to, property)

				if not ok then
					log_error(rbx_instances.cannot_connect_change, nil, apply_to.ClassName, property)
				end

				table.insert(
					scope,
					event:Connect(function()
						callback(apply_to[property])
					end)
				)
			end,
		} :: rbx_instances.SpecialKey<"OnChange">

		KEY_CACHE[property] = key
	end

	return key
end

return OnChange
