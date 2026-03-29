local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")

local RangePair = require("./RangePair")
local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local peek = require("../core_use/peek")

type Self<S, V> = {
	_start: calc.UsedAs<number>,
	_finish: calc.UsedAs<number>,
	_step: calc.UsedAs<number>,

	_pairs_scope: memory.Scope<S>,
	_active_pairs: { iter_range.RangePair<V> },
	_processor: iter_range.RangeDisassemblyProcessor<S, V>,
} & iter.Disassembly<number, V>

local CLASS = table.freeze({
	type = "graph",
	kind = "Disassembly",
	timeliness = "lazy",

	populate = function<S, V>(self: Self<S, V>, use: calc.Use, output: { [number]: V })
		for index, pair in self._active_pairs do
			output[index] = use(pair)
		end
	end,
	_evaluate = function<S, V>(self: Self<S, V>)
		depend(self, self._start)
		depend(self, self._finish)
		depend(self, self._step)

		local old_pairs = self._active_pairs
		local new_pairs = {}

		for new_index = peek(self._start), peek(self._finish), peek(self._step) do
			-- directly reuse objects that are the same
			if old_pairs[new_index] ~= nil then
				new_pairs[new_index] = old_pairs[new_index]
				old_pairs[new_index] = nil

				continue
			end

			-- reuse any existing objects that can be repurposed
			local old_index, reuse_object = next(old_pairs)

			if reuse_object ~= nil then
				old_pairs[old_index] = nil

				reuse_object:invalidate_index(new_index)

				new_pairs[new_index] = reuse_object

				continue
			end

			-- create a new object if none are available
			new_pairs[new_index] = RangePair(self._pairs_scope, new_index, self._processor)
		end

		-- clean up remaining objects
		for _, object in old_pairs do
			object:destroy()
		end

		self._active_pairs = new_pairs

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_rangedisassembly<S, V>(rangediassembly: Self<S, V>)
	cleanup(rangediassembly._pairs_scope)
	rangediassembly._pairs_scope = nil
	rangediassembly._active_pairs = nil
end

local function RangeDisassembly<S, V>(
	scope: memory.Scope<S>,
	processor: iter_range.RangeDisassemblyProcessor<S, V>,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	step: calc.UsedAs<number>?
): iter.Disassembly<number, V>
	step = step or 1

	local new_disassembly: Self<S, V> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_start = start,
		_finish = finish,
		_step = step,

		_active_pairs = {},
		_pairs_scope = derive_scope(scope),
		_processor = processor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_disassembly, destroy_rangedisassembly)

	new_disassembly._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_disassembly
end

return RangeDisassembly
