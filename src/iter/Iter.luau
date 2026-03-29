local calc = require("../core_calc/types")
local iter = require("./types")
local memory = require("../core_memory/types")

local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local generic_use = require("../core_use/generic_use")

type Self<K, V> = {
	_use: calc.Use,
	_disassembly: iter.Disassembly<K, V>,
} & iter.Iter<K, V>

local CLASS = table.freeze({
	type = "State",
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

	new_iter._use = generic_use(new_iter)

	table.insert(scope, destructor(new_iter))

	return new_iter
end

return Iter
