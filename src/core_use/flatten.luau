local state = require("../core_state/types")

local cast_to_state = require("../core_state/cast_to_state")

local function flatten<T>(use: state.Use, x: state.UsedAs<T>): T
	while cast_to_state(x) ~= nil do
		x = use(x)
	end

	return x
end

return flatten
