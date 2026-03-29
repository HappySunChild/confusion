local instances = require("./types")
local memory = require("../core_memory/types")

local change = require("../core_graph/change")
local destructor = require("../core_memory/destructor")

type Self<T> = {
	_event: RBXScriptConnection,
} & instances.AttributeOf<T>

local CLASS = table.freeze({
	type = "state",
	kind = "AttributeOf",
	timeliness = "lazy",
	using = table.freeze({}),

	_evaluate = function()
		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_attributeof<T>(attributeof: Self<T>)
	attributeof._event:Disconnect()
end

local function AttributeOf<T>(
	scope: memory.Scope,
	instance: Instance,
	attribute: string
): instances.AttributeOf<T>
	local event = instance:GetAttributeChangedSignal(attribute)

	local new_attribute: Self<T> = setmetatable({
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

	table.insert(scope, destructor(new_attribute, destroy_attributeof))

	return new_attribute
end

return AttributeOf
