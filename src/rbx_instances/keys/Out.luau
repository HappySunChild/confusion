const memory = require("../../core_memory/types")
const rbx_instances = require("../types")
const state = require("../../core_state/types")

const ExternalLogger = require("../../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const xtypeof = require("../../core_graph/xtypeof")

const KEY_CACHE = {}

const function Out(property: string): rbx_instances.SpecialKey<"Out">
	local key = KEY_CACHE[property]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "Out",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, value: state.Value<any>)
				if xtypeof(value) ~= "state" or value.kind ~= "Value" then
					log_error(rbx_instances.invalid_out_type, nil, typeof(value))
				end

				const event = apply_to:GetPropertyChangedSignal(property)

				table.insert(
					scope,
					event:Connect(function()
						value:set(apply_to[property])
					end)
				)
			end,
		} :: rbx_instances.SpecialKey<"Out">

		KEY_CACHE[property] = key
	end

	return key
end

return Out
