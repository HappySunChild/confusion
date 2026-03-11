local binds = require("./types")
local instances = require("../roblox_instances/types")
local memory = require("../core_memory/types")

local change = require("../core_graph/change")
local destructor = require("../core_memory/destructor")
local log_error = require("../core_logging/log_error")

type Self<T> = {
	_event: RBXScriptConnection,
} & binds.PropertyOf<T>

local CLASS = table.freeze({
	type = "State",
	kind = "PropertyOf",
	timeliness = "lazy",
	using = table.freeze({}),

	_evaluate = function()
		return true
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

local function destroy_propertyof<T>(propertyof: Self<T>)
	propertyof._event:Disconnect()
end

local function PropertyOf(
	scope: memory.Scope,
	instance: Instance,
	property: string
): binds.PropertyOf<unknown>
	local ok, event: RBXScriptSignal = pcall(instance.GetPropertyChangedSignal, instance, property)

	if not ok then
		log_error(instances.cannot_connect_change, nil, instance.ClassName, tostring(property))
	end

	local new_property: binds.PropertyOf<unknown> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},

		_cached_value = instance[property],
		_event = nil,
	}, METATABLE) :: any
	new_property._event = event:Connect(function()
		new_property._cached_value = instance[property]

		change(new_property)
	end)

	table.insert(scope, destructor(new_property, destroy_propertyof))

	return new_property
end

return PropertyOf
