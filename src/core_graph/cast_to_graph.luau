local graph = require("./types")

local function cast_to_graph(x: any): graph.GraphNode?
	if typeof(x) == "table" and x.created_at ~= nil and x.users ~= nil and x.using ~= nil then
		return x :: graph.GraphNode
	end

	return nil
end

return cast_to_graph
