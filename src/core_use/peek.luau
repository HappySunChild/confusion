const state = require("../core_state/types")

const cast_to_state = require("../core_state/cast_to_state")
const evaluate = require("../core_graph/evaluate")

const function peek<T>(x: state.UsedAs<T>): T
	-- should peek error with use_after_destroy on invalid objects?
	if cast_to_state(x) ~= nil then
		evaluate(x)

		return x._cached_value :: T
	end

	return x :: T
end

return peek
