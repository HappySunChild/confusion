const memory = require("../core_memory/types")
const rbx_binds = require("./types")

const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "AttributeOf",
		timeliness = "lazy",
		using = table.freeze({}),

		evaluate = function()
			return true
		end,
	}),
})

const function AttributeOf<T>(scope: memory.Scope, instance: Instance, attribute: string): rbx_binds.AttributeOf<T>
	const new_attributeof = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		cached_value = instance:GetAttribute(attribute),
	}, CLASS_MT) :: any

	table.insert(
		scope,
		instance:GetAttributeChangedSignal(attribute):Connect(function()
			new_attributeof.cached_value = instance:GetAttribute(attribute)
			change(new_attributeof)
		end)
	)

	const oldest_task = destructor(new_attributeof)
	new_attributeof._oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_attributeof
end

return AttributeOf
