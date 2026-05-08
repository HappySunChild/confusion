local graph = require("../core_graph/types")

local cast_to_getter = require("../core_graph/cast_to_getter")

local function peek<T>(value: graph.UsedAs<T>): T
	return if cast_to_getter(value) then (value :: graph.usegetter<T>).raw() else value
end

return peek
