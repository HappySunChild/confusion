local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local Iter = require("../iter/Iter")

local ComputedPair = require("./ComputedPair")
local ForDisassembly = require("./ForDisassembly")

local function ForValues<S, IK, IV, OV>(
	scope: memory.Scope<S>,
	input_table: state.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForValuesProcessor<S, IV, OV>
): iter.Iter<IK, OV> | { [IK]: OV }
	local augmented_processor = function(
		use: state.Use,
		scope: memory.Scope<S>,
		input_key: IK,
		input_value: IV
	)
		local new_value = processor(use, scope, input_value)

		return input_key, new_value
	end

	local augmented_constructor = function(
		scope: memory.Scope<S>,
		initial_key: IK,
		initial_value: IV
	)
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
