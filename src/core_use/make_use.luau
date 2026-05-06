local graph = require("../core_graph/types")
local state = require("../core_calc/types")

local function make_use(capture: graph.capture)
	local function use<T>(value: state.UsedAs<T>): T
		return if type(value) == "function" then value(capture) else value
	end

	return use
end

return make_use
