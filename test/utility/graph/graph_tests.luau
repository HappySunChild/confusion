--!strict
local graph = require("@fusion/core_graph/types")

local function validity(...: graph.Validity)
	local possibilities = { ... }

	return function(node: graph.GraphNode): (boolean, string?)
		if table.find(possibilities, node.validity) == nil then
			return false,
				`Node was {node.validity} instead of {table.concat(possibilities, " or ")}`
		end

		return true, nil
	end
end

local function change_time_exists(node: graph.GraphNode): (boolean, string?)
	if node.last_change == nil then
		return false, "Node had a nil change_time"
	end

	return true, nil
end

local graph_tests = {
	validity = validity,
	change_time_exists = change_time_exists,
}

return graph_tests
