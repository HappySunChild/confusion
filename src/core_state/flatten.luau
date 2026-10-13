const state = require("./types")

const cast_to_state = require("./cast_to_state")

const function flatten<T>(use: state.Use, x: state.UsedAs<T>): T
	while cast_to_state(x) ~= nil do
		x = use(x)
	end

	return x :: T
end

return flatten
