local calc = require("../core_calc/types")
local iter = require("../iter/types")
local iter_for = require("./types")
local memory = require("../core_memory/types")

local Iter = require("../iter/Iter")

local ComputedPair = require("./ComputedPair")
local ForDisassembly = require("./ForDisassembly")
local check_dissolvable = require("./check_dissolvable")

local function ForPairs<S, IK, IV, OK, OV>(
	scope: memory.Scope<S>,
	input_table: calc.UsedAs<{ [IK]: IV }>,
	processor: iter_for.ForPairsProcessor<S, IK, IV, OK, OV>
): iter.Iter<OK, OV> | { [OK]: OV }
	-- local can_dissolve, constant = check_dissolvable(scope, input_table, processor)

	-- if can_dissolve then
	-- 	return constant
	-- end

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
