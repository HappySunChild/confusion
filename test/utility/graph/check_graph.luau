--!strict
local graph = require("@fusion/core_graph/types")

local function check_graph(
	nodes: { graph.GraphNode },
	test: (graph.GraphNode) -> (boolean, string?)
): (boolean, string?)
	for _, node in nodes do
		local ok, message = test(node)

		if ok == false then
			return false, message or "Missing test error message"
		end
	end

	return true, nil
end

return check_graph
