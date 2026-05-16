const graph = require("../core_graph/types")

const function destructor(node: graph.GraphNode, auxiliary: (node: graph.GraphNode) -> ()?): () -> ()
	const function destroy()
		node.scope = nil

		const using = node.using

		for dependency in using do
			dependency.users[node] = nil
			using[dependency] = nil
		end

		const users = node.users

		for user in users do
			user.using[node] = nil
			users[user] = nil
		end

		if auxiliary ~= nil then
			auxiliary(node)
		end
	end

	return destroy
end

return destructor
