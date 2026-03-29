--!strict
local graph = require("@fusion/core_graph/types")
local standard_graph_shapes = require("./standard_graph_shapes")

export type GraphNode = {
	id: string,
} & graph.GraphNode

export type Graph = {
	shape: standard_graph_shapes.GraphShape,
	nodes: { [string]: GraphNode },
	all_nodes: { GraphNode },
}

local function assemble_graph(shape: standard_graph_shapes.GraphShape): Graph
	local nodes = {}
	local all_nodes = {}

	for _, id in shape.ids do
		local new_node: GraphNode = {
			id = id,
			scope = nil,
			created_at = 0,
			users = {},
			using = {},
			type = "graph",
			timeliness = "lazy",
			validity = "valid",
			_evaluate = function()
				return true
			end,
			_oldest_task = function() end,
		}

		nodes[id] = new_node
		table.insert(all_nodes, new_node)
	end

	for _, edge in shape.edges do
		local from = nodes[edge.from]
		local to = nodes[edge.to]
		from.users[to] = true
		to.using[from] = true
	end

	return {
		shape = shape,
		nodes = nodes,
		all_nodes = all_nodes,
	}
end

return assemble_graph
