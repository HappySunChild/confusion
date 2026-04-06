local graph = require("./types")

local function cast_to_graph(x: unknown): graph.GraphNode?
	if typeof(x) == "table" and x.created_at ~= nil and x.users ~= nil and x.using ~= nil then
		return x
	end

	return nil
end

return cast_to_graph
