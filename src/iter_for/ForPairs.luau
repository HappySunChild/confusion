local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local Iter = require("../iter/Iter")

local ComputedPair = require("./ComputedPair")
local ForDisassembly = require("./ForDisassembly")

local function ForPairs<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	input_table: state.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
): iter.Iter<OK, OV> | { [OK]: OV }
	local augmented_constructor = function(
		scope: memory.Scope<S>,
		initial_key: IK,
		initial_value: IV
	)
		return ComputedPair(scope, initial_key, initial_value, false, false, processor)
	end

	return Iter(scope, ForDisassembly(scope, input_table, augmented_constructor))
end

return ForPairs
