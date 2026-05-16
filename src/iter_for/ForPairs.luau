const iter = require("../iter/types")
const iter_for = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const Iter = require("../iter/Iter")

const ComputedPair = require("./ComputedPair")
const ForDisassembly = require("./ForDisassembly")

const function ForPairs<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	input_table: state.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
): iter.Iter<OK, OV> | { [OK]: OV }
	const augmented_constructor = function(scope: memory.Scope<S>, initial_key: IK, initial_value: IV)
		return ComputedPair(scope, initial_key, initial_value, false, false, processor)
	end

	return Iter(scope, ForDisassembly(scope, input_table, augmented_constructor))
end

return ForPairs
