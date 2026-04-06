local calc = require("../core_calc/types")

local cast_to_state = require("../core_calc/cast_to_state")
local evaluate = require("../core_graph/evaluate")

local function peek<T>(x: calc.UsedAs<T>): T
	-- should peek error with use_after_destroy on invalid objects?
	if cast_to_state(x) ~= nil then
		evaluate(x)

		return x._cached_value :: T
	end

	return x :: T
end

return peek
