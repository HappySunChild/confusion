local assemble_graph = require("./assemble_graph")

local VALIDITY_SYMBOLS = { valid = "✓", invalid = "✕", busy = "○", dirty = "◇" }
local TIMELINESS_SYMBOLS = { lazy = "β", eager = "Ω" }
local ARROWS = { "↑", "↗", "→", "↘", "↓", "↙", "←", "↖" }

local function format_graph(graph: assemble_graph.Graph): string
	local output = {}

	local line = 1
	local repr_width = 0

	local graph_shape = graph.shape

	while true do
		local edge = graph_shape.edges[line]
		local repr_line = graph_shape.repr[line]
		local node_id = graph_shape.ids[line]

		if edge == nil and repr_line == nil and node_id == nil then
			break
		end

		if repr_line ~= nil then
			repr_width = math.max(repr_width, utf8.len(repr_line) or 0)
		else
			repr_line = string.rep(" ", repr_width)
		end

		local repr_line_no_arrows = repr_line

		for _, arrow in ARROWS do
			repr_line_no_arrows = string.gsub(repr_line_no_arrows, arrow, " ")
		end

		local validity_line = string.gsub(repr_line_no_arrows, "%w+", function(id: string)
			local node = graph.nodes[id]

			if node == nil then
				return id
			end

			return string.rep(VALIDITY_SYMBOLS[node.validity] or "?", #id)
		end)
		local timeliness_line = string.gsub(repr_line_no_arrows, "%w+", function(id: string)
			local node = graph.nodes[id]

			if node == nil then
				return id
			end

			return string.rep(TIMELINESS_SYMBOLS[node.timeliness] or "?", #id)
		end)

		local edge_line = ""

		if edge ~= nil then
			edge_line = `{edge.from} → {edge.to}`
		end

		edge_line ..= string.rep(" ", 5 - utf8.len(edge_line) or 0)

		local change_line = ""

		if node_id ~= nil then
			local node = graph.nodes[node_id]

			if node ~= nil then
				change_line ..= `{node_id} ◷ {node.last_change}`
			end
		end

		table.insert(
			output,
			`  │  {repr_line}  │  {validity_line}  │  {timeliness_line}  │  {edge_line}  │  {change_line}`
		)

		line += 1
	end

	return table.concat(output, "\n")
end

return format_graph
