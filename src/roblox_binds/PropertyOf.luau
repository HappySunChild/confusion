local instances = require("../roblox_instances/types")
local memory = require("../core_memory/types")
local rbx_binds = require("./types")

local change = require("../core_graph/change")
local destructor = require("../core_memory/destructor")
local log_error = require("../core_logging/log_error")

type Self<T> = {
	_event: RBXScriptConnection,
} & rbx_binds.PropertyOf<T>

local CLASS = table.freeze({
	type = "state",
	kind = "PropertyOf",
	timeliness = "lazy",
	using = table.freeze({}),

	_evaluate = function()
		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_propertyof<T>(propertyof: Self<T>)
	propertyof._event:Disconnect()
end

local function PropertyOf(scope: memory.Scope, instance: Instance, property: string): rbx_binds.PropertyOf<unknown>
	local ok, event: RBXScriptSignal = pcall(instance.GetPropertyChangedSignal, instance, property)

	if not ok then
		log_error(instances.cannot_connect_change, nil, instance.ClassName, tostring(property))
	end

	local new_property: rbx_binds.PropertyOf<unknown> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		_cached_value = instance[property],
		_event = nil,
	}, CLASS_METATABLE) :: any
	new_property._event = event:Connect(function()
		new_property._cached_value = instance[property]
		change(new_property)
	end)

	local oldest_task = destructor(new_property, destroy_propertyof)

	new_property._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_property
end

return PropertyOf
