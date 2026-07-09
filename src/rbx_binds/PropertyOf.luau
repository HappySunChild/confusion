const instances = require("../rbx_instances/types")
const memory = require("../core_memory/types")
const rbx_binds = require("./types")

const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")
const log_error = require("../core_logging/log_error")

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "PropertyOf",
		timeliness = "lazy",
		using = table.freeze({}),

		evaluate = function()
			return true
		end,
	}),
})

const function PropertyOf(scope: memory.Scope, instance: Instance, property: string): rbx_binds.PropertyOf<unknown>
	const ok, event: RBXScriptSignal = pcall(instance.GetPropertyChangedSignal, instance, property)

	if not ok then
		log_error(instances.cannot_connect_change, nil, instance.ClassName, tostring(property))
	end

	const new_propertyof: rbx_binds.PropertyOf<unknown> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		cached_value = instance[property],
	}, CLASS_MT) :: any

	table.insert(
		scope,
		event:Connect(function()
			new_propertyof.cached_value = instance[property]
			change(new_propertyof)
		end)
	)

	const oldest_task = destructor(new_propertyof)
	new_propertyof._oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_propertyof
end

return PropertyOf
