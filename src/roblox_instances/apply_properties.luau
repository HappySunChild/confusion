local instances = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local Parent = require("./keys/Parent")
local cast_to_state = require("../core_state/cast_to_state")
local log_error_nonfatal = require("../core_logging/log_error_nonfatal")
local observe = require("../core_graph/observe")
local parse_error = require("../core_logging/parse_error")
local peek = require("../core_use/peek")
local sort_keys = require("./sort_keys")
local xtypeof = require("../core_graph/xtypeof")

local function raw_set_property(instance: Instance, property: string, value: any)
	instance[property] = value
end

local function test_property_assignable(instance: Instance, property: string)
	instance[property] = instance[property]
end

local function set_property(instance: Instance, property: string, value: any)
	local ok, err = xpcall(raw_set_property, parse_error, instance, property, value)

	if ok then
		return
	end

	if pcall(test_property_assignable, instance, property) == false then
		log_error_nonfatal(instances.property_cannot_assign, nil, instance.ClassName, property)

		return
	end

	local given_type = typeof(value)
	local expected_type = typeof(instance[property])

	if given_type == expected_type then
		log_error_nonfatal(instances.property_assign_error, err)
	else
		log_error_nonfatal(
			instances.invalid_property_type,
			nil,
			instance.ClassName,
			property,
			expected_type,
			given_type
		)
	end
end

local function apply_property(
	scope: memory.Scope,
	instance: Instance,
	property: string,
	value: state.UsedAs<any>
)
	set_property(instance, property, peek(value))

	if cast_to_state(value) ~= nil then
		observe(scope, value, function()
			set_property(instance, property, peek(value))
		end)
	end
end

local function apply_properties(
	scope: memory.Scope,
	instance: Instance,
	properties: instances.Properties
)
	local n_properties = table.clone(properties)

	n_properties[Parent] = n_properties.Parent
	n_properties.Parent = nil

	local special_keys: { instances.SpecialKey } = {}

	for key, value in n_properties do
		local key_type = xtypeof(key)

		if key_type == "string" then
			apply_property(scope, instance, key, value)
		elseif key_type == "SpecialKey" then
			table.insert(special_keys, key)
		else
			log_error_nonfatal(instances.invalid_key_type, nil, key_type)
		end
	end

	table.sort(special_keys, sort_keys)

	for _, key: instances.SpecialKey in special_keys do
		local value = n_properties[key]
		local ok, err = xpcall(key.apply, parse_error, scope, instance, value)

		if ok then
			continue
		end

		log_error_nonfatal(
			instances.specialkey_apply_error,
			err,
			key.kind,
			instance.ClassName,
			instance.Name,
			value,
			key.stage
		)
	end
end

return apply_properties
