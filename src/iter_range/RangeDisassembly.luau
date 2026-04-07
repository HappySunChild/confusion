local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")

local RangePair = require("./RangePair")
local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local derive_scope = require("../core_memory/derive_scope")
local destructor = require("../core_memory/destructor")
local inner_scope = require("../core_memory/inner_scope")
local peek = require("../core_use/peek")

type Self<S, T> = {
	_start: calc.UsedAs<number>,
	_finish: calc.UsedAs<number>,
	_step: calc.UsedAs<number>,

	_pairs_scope: memory.Scope<S>,
	_current_pairs: { iter_range.RangePair<T> },
	_ordered_pairs: { iter_range.RangePair<T> },
	_processor: iter_range.RangeDisassemblyProcessor<S, T>,
} & iter.Disassembly<number, T>

local CLASS = table.freeze({
	type = "graph",
	kind = "Disassembly",
	timeliness = "lazy",

	populate = function<S, T>(self: Self<S, T>, use: calc.Use, output: { [number]: T })
		for index, pair in self._ordered_pairs do
			output[index] = use(pair)
		end
	end,
	_evaluate = function<S, T>(self: Self<S, T>)
		depend(self, self._start)
		depend(self, self._finish)
		depend(self, self._step)

		local ordered_pairs = self._ordered_pairs
		local cur_pairs = self._current_pairs
		local new_pairs = {}

		table.clear(ordered_pairs)

		for new_index = peek<<number>>(self._start), peek<<number>>(self._finish), peek<<number>>(self._step) do
			-- directly reuse objects that are the same
			local cur_pair = cur_pairs[new_index]

			if cur_pair ~= nil then
				cur_pairs[new_index] = nil
				new_pairs[new_index] = cur_pair

				table.insert(ordered_pairs, cur_pair)

				continue
			end

			-- reuse any existing objects that can be repurposed
			local cur_index, reuse_pair = next(cur_pairs)

			if reuse_pair ~= nil then
				cur_pairs[cur_index] = nil
				new_pairs[new_index] = reuse_pair

				table.insert(ordered_pairs, reuse_pair)

				reuse_pair:invalidate_index(new_index)

				continue
			end

			-- create a new object if none are available
			local new_pair = RangePair(inner_scope(self._pairs_scope), new_index, self._processor)
			new_pairs[new_index] = new_pair

			table.insert(ordered_pairs, new_pair)
		end

		-- clean up remaining objects
		for _, pair in cur_pairs do
			cleanup(pair.scope)
		end

		self._current_pairs = new_pairs

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_rangedisassembly<S, T>(rangediassembly: Self<S, T>)
	cleanup(rangediassembly._pairs_scope)
	rangediassembly._pairs_scope = nil
	rangediassembly._active_pairs = nil
end

local function RangeDisassembly<S, T>(
	scope: memory.Scope<S>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	step: calc.UsedAs<number>?
): iter.Disassembly<number, T>
	step = step or 1

	local new_disassembly: Self<S, T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		_start = start,
		_finish = finish,
		_step = step,

		_ordered_pairs = {},
		_current_pairs = {},
		_pairs_scope = derive_scope(scope),
		_processor = processor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_disassembly, destroy_rangedisassembly)

	new_disassembly._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_disassembly
end

return RangeDisassembly
