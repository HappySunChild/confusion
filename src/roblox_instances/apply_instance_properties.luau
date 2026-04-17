local memory = require("../core_memory/types")
local rbx_instances = require("./types")
local state = require("../core_state/types")

local Children = require("./keys/Children")
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
		log_error_nonfatal(rbx_instances.property_cannot_assign, nil, instance.ClassName, property)

		return
	end

	local given_type = typeof(value)
	local expected_type = typeof(instance[property])

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

local function apply_property(scope: memory.Scope, instance: Instance, property: string, value: state.UsedAs<any>)
	set_property(instance, property, peek(value))

	if cast_to_state(value) ~= nil then
		observe(scope, value, function()
			set_property(instance, property, peek(value))
		end)
	end
end

local function apply_instance_properties(scope: memory.Scope, instance: Instance, properties: rbx_instances.Properties)
	local special_key_values: { [rbx_instances.SpecialKey]: any } = {}

	if properties.Parent then
		special_key_values[Parent] = properties.Parent
	end

	local implicit_children = {}

	for key, value in properties do
		if key == "Parent" then
			continue
		end

		local key_type = xtypeof(key)

		if key_type == "string" then
			apply_property(scope, instance, key, value)
		elseif key_type == "number" then
			table.insert(implicit_children, value)
		elseif key_type == "SpecialKey" then
			special_key_values[key] = value
		else
			log_error_nonfatal(rbx_instances.invalid_key_type, nil, key_type)
		end
	end

	-- if we have implicit children then merge and overwrite our implicit children with any explicitly set children
	if #implicit_children > 0 then
		table.insert(implicit_children, special_key_values[Children])

		special_key_values[Children] = implicit_children
	end

	local special_keys: { rbx_instances.SpecialKey } = {}

	for key in special_key_values do
		table.insert(special_keys, key)
	end

	table.sort(special_keys, sort_keys)

	for _, key: rbx_instances.SpecialKey in special_keys do
		local value = special_key_values[key]
		local ok, err = xpcall(key.apply, parse_error, scope, instance, value)

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
