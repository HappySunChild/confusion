local iter = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local generic_use = require("../core_use/generic_use")

type Self<K, V> = {
	_use: state.Use,
	_disassembly: iter.Disassembly<K, V>,
} & iter.Iter<K, V>

local CLASS = table.freeze({
	type = "state",
	kind = "Iter",
	timeliness = "lazy",

	_evaluate = function<K, V>(self: Self<K, V>): boolean
		if self.scope == nil then
			return false
		end

		local output = self._cached_value
		local disassembly = self._disassembly

		depend(self, disassembly)

		table.clear(output)

		disassembly:populate(self._use, output)

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function Iter<K, V>(scope: memory.Scope, disassembly: iter.Disassembly<K, V>): iter.Iter<K, V>
	local new_iter: Self<K, V> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		_cached_value = {},

		_disassembly = disassembly,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_iter)

	new_iter._oldest_task = oldest_task
	new_iter._use = generic_use(new_iter)

	table.insert(scope, oldest_task)

	return new_iter
end

return Iter
