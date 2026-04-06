--!strict
local graph = require("@fusion/core_graph/types")

type SelectKind = "users" | "using"

local function distance(
	select_from: { graph.GraphNode },
	distance_from: { graph.GraphNode },
	kind: SelectKind,
	desired_distance: number
)
	local is_find_target = {}

	for _, object in distance_from do
		is_find_target[object] = true
	end

	local selection = {}

	for _, node in select_from do
		local search_now = { [node] = true }
		local search_next = {}

		for distance = 0, desired_distance do
			local found = false

			for search_target in search_now do
				if is_find_target[search_target] then
					found = true
					continue
				end

				local search_set = if kind == "using"
					then search_target.using
					else search_target.users

				for other_node in search_set do
					search_next[other_node] = true
				end
			end

			if found then
				if distance ~= desired_distance then
					break
				end

				table.insert(selection, node)
			end

			search_now, search_next = search_next, search_now
			table.clear(search_next)
		end
	end

	return selection
end

local function no_connections(select_from: { graph.GraphNode }, kind: SelectKind)
	local selection = {}

	for _, node in select_from do
		local search_set = if kind == "using" then node.using else node.users

		if next(search_set) == nil then
			table.insert(selection, node)
		end
	end

	return selection
end

local graph_selectors = {
	distance = distance,
	no_connections = no_connections,
}

return graph_selectors
