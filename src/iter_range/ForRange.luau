local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local Iter = require("../iter/Iter")
local RangeDisassembly = require("./RangeDisassembly")

local function ForRange<S, T>(
	scope: memory.Scope<S>,
	start: state.UsedAs<number>,
	finish: state.UsedAs<number>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>,
	step: state.UsedAs<number>?
): iter.Iter<number, T> | { T }
	step = step or 1

	return Iter(scope, RangeDisassembly(scope, processor, start, finish, step))
end

return ForRange
