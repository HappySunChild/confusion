--!strict
--!native
--!optimize 2

const iter = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const depend = require("../core_graph/depend")
const generic_use = require("../core_state/generic_use")
const node_destructor = require("../core_graph/node_destructor")

type Self<K, V> = {
	use: state.Use,
	disassembly: iter.Disassembly<K, V>,
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
			const disassembly = self.disassembly

			depend(self, disassembly)

			table.clear(output)

			disassembly:populate(self.use, output)

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

		disassembly = disassembly,
	}, CLASS_MT) :: any

	new_iter.use = generic_use(new_iter)

	const oldest_task = node_destructor(new_iter)
	new_iter.oldest_task = oldest_task
	table.insert(scope, oldest_task)

	return new_iter
end

return Iter
