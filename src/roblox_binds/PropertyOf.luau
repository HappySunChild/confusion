const instances = require("../roblox_instances/types")
const memory = require("../core_memory/types")
const rbx_binds = require("./types")

const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")
const log_error = require("../core_logging/log_error")

type Self<T> = {
	_event: RBXScriptConnection,
} & rbx_binds.PropertyOf<T>

const CLASS = table.freeze({
	type = "state",
	kind = "PropertyOf",
	timeliness = "lazy",
	using = table.freeze({}),

	_evaluate = function()
		return true
	end,
})
const CLASS_METATABLE = table.freeze({ __index = CLASS })

const function destroy_propertyof<T>(propertyof: Self<T>)
	propertyof._event:Disconnect()
end

const function PropertyOf(scope: memory.Scope, instance: Instance, property: string): rbx_binds.PropertyOf<unknown>
	const ok, event: RBXScriptSignal = pcall(instance.GetPropertyChangedSignal, instance, property)

	if not ok then
		log_error(instances.cannot_connect_change, nil, instance.ClassName, tostring(property))
	end

	const new_property: rbx_binds.PropertyOf<unknown> = setmetatable({
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

	const oldest_task = destructor(new_property, destroy_propertyof)

	new_property._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_property
end

return PropertyOf
