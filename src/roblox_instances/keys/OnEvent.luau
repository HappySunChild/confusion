local instances = require("../types")
local memory = require("../../core_memory/types")

local log_error = require("../../core_logging/log_error")

local function get_property(instance: Instance, key: string)
	return instance[key]
end

local KEY_CACHE = {}

local function OnEvent(event_name: string): instances.SpecialKey<"OnEvent">
	local key = KEY_CACHE[event_name]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "OnChange",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, callback: (...unknown) -> ())
				local ok, event = pcall(get_property, apply_to, event_name)

				if not ok or typeof(event) ~= "RBXScriptSignal" then
					log_error(instances.cannot_connect_event, nil, apply_to.ClassName, event_name)
				end

				table.insert(scope, event:Connect(callback))
			end,
		} :: instances.SpecialKey<"OnEvent">

		KEY_CACHE[event_name] = key
	end

	return key
end

return OnEvent
