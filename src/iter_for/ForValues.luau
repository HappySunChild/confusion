const iter = require("../iter/types")
const iter_for = require("./types")
const memory = require("../core_memory/types")
const state = require("../core_state/types")

const Iter = require("../iter/Iter")

const ComputedPair = require("./ComputedPair")
const ForDisassembly = require("./ForDisassembly")

const function ForValues<S, IK, IV, OV>(
	scope: memory.Scope<S>,
	input_table: state.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForValuesProcessor<S, IV, OV>
): iter.Iter<IK, OV> | { [IK]: OV }
	const augmented_processor = function(use: state.Use, scope: memory.Scope<S>, input_key: IK, input_value: IV)
		const new_value = processor(use, scope, input_value)

		return input_key, new_value
	end

	const augmented_constructor = function(scope: memory.Scope<S>, initial_key: IK, initial_value: IV)
		return ComputedPair(
			scope,
			initial_key,
			initial_value,
			true, -- ignore key invalidations
			false,
			augmented_processor
		)
	end

	return Iter(scope, ForDisassembly(scope, input_table, augmented_constructor))
end

return ForValues
