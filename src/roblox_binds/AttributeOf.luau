const memory = require("../core_memory/types")
const rbx_binds = require("./types")

const change = require("../core_graph/change")
const destructor = require("../core_memory/destructor")

type Self<T> = {
	_event: RBXScriptConnection,
} & rbx_binds.AttributeOf<T>

const CLASS = table.freeze({
	type = "state",
	kind = "AttributeOf",
	timeliness = "lazy",
	using = table.freeze({}),

	_evaluate = function()
		return true
	end,
})
const CLASS_METATABLE = table.freeze({ __index = CLASS })

const function destroy_attributeof<T>(attributeof: Self<T>)
	attributeof._event:Disconnect()
end

const function AttributeOf<T>(scope: memory.Scope, instance: Instance, attribute: string): rbx_binds.AttributeOf<T>
	const event = instance:GetAttributeChangedSignal(attribute)

	const new_attribute: Self<T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		_cached_value = instance:GetAttribute(attribute),
		_event = nil,
	}, CLASS_METATABLE) :: any
	new_attribute._event = event:Connect(function()
		new_attribute._cached_value = instance:GetAttribute(attribute)
		change(new_attribute)
	end)

	const oldest_task = destructor(new_attribute, destroy_attributeof)

	new_attribute._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_attribute
end

return AttributeOf
