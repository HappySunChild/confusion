local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")
local state = require("../core_state/types")

local Iter = require("../iter/Iter")

local ComputedPair = require("./ComputedPair")
local ForDisassembly = require("./ForDisassembly")

local function ForKeys<S, IK, IV, OK>(
	scope: memory.Scope<S>,
	input_table: state.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForKeysProcessor<S, IK, OK>
): iter.Iter<OK, IV> | { [OK]: IV }
	local augmented_processor = function(use: state.Use, scope: memory.Scope<S>, input_key: IK, input_value: IV)
		local new_key = processor(use, scope, input_key)

		return new_key, input_value
	end

	local augmented_constructor = function(scope: memory.Scope<S>, initial_key: IK, initial_value: IV)
		return ComputedPair(
			scope,
			initial_key,
			initial_value,
			false,
			true, -- ignore value invalidations
			augmented_processor
		)
	end

	return Iter(scope, ForDisassembly(scope, input_table, augmented_constructor))
end

return ForKeys
