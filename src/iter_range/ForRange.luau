local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_range = require("./types")
local memory = require("../core_memory/types")

local Iter = require("../iter/Iter")
local RangeDisassembly = require("./RangeDisassembly")

local function ForRange<S, T>(
	scope: memory.Scope<S>,
	start: calc.UsedAs<number>,
	finish: calc.UsedAs<number>,
	processor: iter_range.RangeDisassemblyProcessor<S, T>,
	step: calc.UsedAs<number>?
): iter.Iter<number, T> | { T }
	step = step or 1

	return Iter(scope, RangeDisassembly(scope, processor, start, finish, step))
end

return ForRange
