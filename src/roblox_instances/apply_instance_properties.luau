const memory = require("../core_memory/types")
const rbx_instances = require("./types")
const state = require("../core_state/types")

const Parent = require("./keys/Parent")
const cast_to_state = require("../core_state/cast_to_state")
const log_error_nonfatal = require("../core_logging/log_error_nonfatal")
const observe = require("../core_graph/observe")
const parse_error = require("../core_logging/parse_error")
const peek = require("../core_use/peek")
const sort_keys = require("./sort_keys")
const xtypeof = require("../core_graph/xtypeof")

const function raw_set_property(instance: Instance, property: string, value: any)
	instance[property] = value
end

const function test_property_assignable(instance: Instance, property: string)
	instance[property] = instance[property]
end

const function set_property(instance: Instance, property: string, value: any)
	const ok, err = xpcall(raw_set_property, parse_error, instance, property, value)

	if ok then
		return
	end

	if pcall(test_property_assignable, instance, property) == false then
		log_error_nonfatal(rbx_instances.property_cannot_assign, nil, instance.ClassName, property)

		return
	end

	const given_type = typeof(value)
	const expected_type = typeof(instance[property])

	if given_type == expected_type then
		log_error_nonfatal(rbx_instances.property_assign_error, err)
	else
		log_error_nonfatal(
			rbx_instances.invalid_property_type,
			nil,
			instance.ClassName,
			property,
			expected_type,
			given_type
		)
	end
end

const function apply_property(scope: memory.Scope, instance: Instance, property: string, value: state.UsedAs<any>)
	set_property(instance, property, peek(value))

	if cast_to_state(value) ~= nil then
		observe(scope, value, function()
			set_property(instance, property, peek(value))
		end)
	end
end

const function apply_instance_properties(scope: memory.Scope, instance: Instance, properties: rbx_instances.Properties)
	const special_key_values: { [rbx_instances.SpecialKey]: any } = {}

	special_key_values[Parent] = properties.Parent
	properties.Parent = nil

	for key, value in properties do
		const key_type = xtypeof(key)

		if key_type == "string" then
			apply_property(scope, instance, key, value)
		elseif key_type == "SpecialKey" then
			special_key_values[key] = value
		else
			log_error_nonfatal(rbx_instances.invalid_key_type, debug.traceback(), key_type)
		end
	end

	const special_keys: { rbx_instances.SpecialKey } = {}

	for key in special_key_values do
		table.insert(special_keys, key)
	end

	table.sort(special_keys, sort_keys)

	for _, key: rbx_instances.SpecialKey in special_keys do
		const value = special_key_values[key]
		const ok, err = xpcall(key.apply, parse_error, scope, instance, value)

		if ok then
			continue
		end

		log_error_nonfatal(
			rbx_instances.specialkey_apply_error,
			err,
			key.kind,
			instance.ClassName,
			instance.Name,
			value,
			key.stage
		)
	end
end

return apply_instance_properties
