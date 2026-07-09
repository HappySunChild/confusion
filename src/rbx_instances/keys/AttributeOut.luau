const memory = require("../../core_memory/types")
const rbx_instances = require("../types")
const state = require("../../core_state/types")

const ExternalLogger = require("../../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const xtypeof = require("../../core_graph/xtypeof")

const KEY_CACHE = {}

const function AttributeOut(attribute: string): rbx_instances.SpecialKey<"AttributeOut">
	local key = KEY_CACHE[attribute]

	if key == nil then
		key = {
			type = "SpecialKey",
			kind = "AttributeOut",
			stage = "observer",
			apply = function(scope: memory.Scope, apply_to: Instance, value: state.Value<any>)
				if xtypeof(value) ~= "state" or value.Kind ~= "Value" then
					log_error(rbx_instances.invalid_out_type, nil, typeof(value))
				end

				const event = apply_to:GetAttributeChangedSignal(attribute)

				table.insert(
					scope,
					event:Connect(function()
						value:set(apply_to:GetAttribute(attribute))
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
