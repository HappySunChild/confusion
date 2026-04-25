local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local RangePair = require("./RangePair")
local cleanup = require("../core_memory/cleanup")
local depend = require("../core_graph/depend")
local destructor = require("../core_memory/destructor")
local inner_scope = require("../core_memory/inner_scope")
local is_similar = require("../core_state/is_similar")
local mark_dirty = require("../core_graph/mark_dirty")
local peek = require("../core_use/peek")

type Self<S, T> = {
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	increment: state.UsedAs<number>,

	_pairs_scope: memory.Scope<S>,
	_current_pairs: { iter_range.RangePair<T> },
	_ordered_pairs: { iter_range.RangePair<T> },
	_processor: iter_range.RangeDisassemblyProcessor<S, T>,
} & iter.Disassembly<number, T>

local function invalidate_index<T>(rangepair: iter_range.RangePair<T>, new_index: number)
	if is_similar(rangepair.input_index, new_index) then
		return
	end

	rangepair.input_index = new_index

	mark_dirty(rangepair)
end

local CLASS = table.freeze({
	type = "graph",
	kind = "Disassembly",
	timeliness = "lazy",

	populate = function<S, T>(self: Self<S, T>, use: state.Use, output: { [number]: T })
		for index, pair in self._ordered_pairs do
			output[index] = use(pair)
		end
	end,
	_evaluate = function<S, T>(self: Self<S, T>)
		depend(self, self.start)
		depend(self, self.finish)
		depend(self, self.increment)

		local old_rangepairs = self._current_pairs
		local new_rangepairs = {}

		local ordered_rangepairs = self._ordered_pairs
		table.clear(ordered_rangepairs)

		for new_index = peek<<number>>(self.start), peek<<number>>(self.finish), peek<<number>>(self.increment) do
			-- directly reuse objects that are the same
			local old_rangepair = old_rangepairs[new_index]

			if old_rangepair ~= nil then
				old_rangepairs[new_index] = nil
				new_rangepairs[new_index] = old_rangepair

				table.insert(ordered_rangepairs, old_rangepair)

				continue
			end

			-- reuse any existing objects that can be repurposed
			local old_index, reuse_rangepair = next(old_rangepairs)

			if reuse_rangepair ~= nil then
				old_rangepairs[old_index] = nil
				new_rangepairs[new_index] = reuse_rangepair

				table.insert(ordered_rangepairs, reuse_rangepair)

				invalidate_index(reuse_rangepair, new_index)

				continue
			end

			-- create a new object if none are available
			local new_pair = RangePair(inner_scope(self._pairs_scope), new_index, self._processor)
			new_rangepairs[new_index] = new_pair

			table.insert(ordered_rangepairs, new_pair)
		end

		-- clean up remaining objects
		for _, rangepair in old_rangepairs do
			cleanup(rangepair.scope)
		end

		self._current_pairs = new_rangepairs

		return true
	end,
})
local CLASS_METATABLE = table.freeze({ __index = CLASS })

local function destroy_rangedisassembly<S, T>(rangediassembly: Self<S, T>)
	rangediassembly._pairs_scope = nil
	rangediassembly._active_pairs = nil
end

local function RangeDisassembly<S, T>(
	scope: memory.Scope<S>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	step: state.UsedAs<number>?
): iter.Disassembly<number, T>
	step = step or 1

	local new_disassembly: Self<S, T> = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		users = {},
		using = {},

		start = start,
		finish = finish,
		increment = step,

		_ordered_pairs = {},
		_current_pairs = {},
		_pairs_scope = inner_scope(scope),
		_processor = processor,
	}, CLASS_METATABLE) :: any

	local oldest_task = destructor(new_disassembly, destroy_rangedisassembly)

	new_disassembly._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_disassembly
end

return RangeDisassembly
