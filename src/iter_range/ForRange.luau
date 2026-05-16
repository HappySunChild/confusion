const iter = require("../iter/types")
const iter_range = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const Iter = require("../iter/Iter")
const RangeDisassembly = require("./RangeDisassembly")

const function ForRange<S, T>(
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
