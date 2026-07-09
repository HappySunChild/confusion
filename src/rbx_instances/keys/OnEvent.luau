const memory = require("../../core_memory/types")
const rbx_instances = require("../types")

const log_error = require("../../core_logging/log_error")

const function get_property(instance: Instance, key: string)
	return instance[key]
end

const KEY_CACHE = {}

const function OnEvent(event_name: string): rbx_instances.SpecialKey<"OnEvent">
	local key = KEY_CACHE[event_name]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "OnChange",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, callback: (...unknown) -> ())
				const ok, event = pcall(get_property, apply_to, event_name)

				if not ok or typeof(event) ~= "RBXScriptSignal" then
					log_error(rbx_instances.cannot_connect_event, nil, apply_to.ClassName, event_name)
				end

				table.insert(scope, event:Connect(callback))
			end,
		} :: rbx_instances.SpecialKey<"OnEvent">

		KEY_CACHE[event_name] = key
	end

	return key
end

return OnEvent
