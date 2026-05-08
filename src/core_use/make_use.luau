local graph = require("../core_graph/types")

local cast_to_getter = require("../core_graph/cast_to_getter")

local function make_use(capture: graph.capture)
	local function use<T>(value: graph.UsedAs<T>): T
		return if cast_to_getter(value) then (value :: graph.usegetter<T>).raw(capture) else value
	end

	return use
end

return make_use
