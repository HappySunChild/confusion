local graph = require("../core_graph/types")

--- A generic destroy function for graph nodes.
local function destroy_node(node: graph.GraphNode)
	node.scope = nil

	local using = node.using

	for dependency in using do
		dependency.users[node] = nil
		using[dependency] = nil
	end

	local users = node.users

	for user in users do
		user.using[node] = nil
		users[user] = nil
	end
end

local function destructor(
	node: graph.GraphNode,
	auxiliary: (node: graph.GraphNode) -> ()?
): () -> ()
	local function destroy()
		destroy_node(node)

		if auxiliary ~= nil then
			auxiliary(node)
		end
	end

	return destroy
end

return destructor
