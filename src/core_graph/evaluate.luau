local graph = require("./types")

local log_error = require("../core_logging/log_error")

--[[
	Evaluates the graph object if necessary, so that it is up to date.
	Returns `true` if it meaningfully changed.

	https://fluff.blog/2024/04/16/monotonic-painting.html
]]
local function evaluate(node: graph.GraphNode, force_computation: boolean?): boolean
	if node.validity == "busy" then
		log_error(graph.infinite_loop)
	end

	local first_evaluation = node.last_change == nil or node.last_compute == nil
	local is_dirty = node.validity == "dirty"
	local is_invalid = node.validity == "invalid"

	if not (first_evaluation or is_dirty or is_invalid or force_computation) then
		return false
	end

	local needs_computation = force_computation or first_evaluation or is_dirty

	-- check dependencies to see if any of them have updated before use, if so then we need to be reevaluated
	if not needs_computation then
		for dependency in node.using do
			evaluate(dependency, false)

			if dependency.last_change :: number > node.last_compute :: number then
				needs_computation = true

				break
			end
		end
	end

	local meaningfully_changed = false

	if needs_computation then
		-- clear dependencies
		for dependency in node.using do
			dependency.users[node] = nil
			node.using[dependency] = nil
		end

		node.validity = "busy"

		meaningfully_changed = node:_evaluate() or first_evaluation

		node.last_compute = os.clock()
	end

	if meaningfully_changed then
		node.last_change = os.clock()
	end

	node.validity = "valid"

	return meaningfully_changed
end

return evaluate
