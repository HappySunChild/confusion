const iter = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const depend = require("../core_graph/depend")
const destructor = require("../core_memory/destructor")
const generic_use = require("../core_use/generic_use")

type Self<K, V> = {
	_use: state.Use,
	_disassembly: iter.Disassembly<K, V>,
} & iter.Iter<K, V>

const CLASS_MT = table.freeze({
	__index = table.freeze({
		type = "state",
		kind = "Iter",
		timeliness = "lazy",

		evaluate = function<K, V>(self: Self<K, V>): boolean
			if self.scope == nil then
				return false
			end

			const output = self.cached_value
			const disassembly = self._disassembly

			depend(self, disassembly)

			table.clear(output)

			disassembly:populate(self._use, output)

			return true
		end,
	}),
})

const function Iter<K, V>(scope: memory.Scope, disassembly: iter.Disassembly<K, V>): iter.Iter<K, V>
	const new_iter: Self<K, V> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		using = {},
		users = {},

		cached_value = {},

		_disassembly = disassembly,
	}, CLASS_MT) :: any

	new_iter._use = generic_use(new_iter)

	const oldest_task = destructor(new_iter)
	new_iter._oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_iter
end

return Iter
