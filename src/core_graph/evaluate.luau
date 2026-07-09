const graph = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const next_version = require("./next_version")

--[[
	Evaluates the graph object if necessary, so that it is up to date.
	Returns `true` if it meaningfully changed.

	https://fluff.blog/2024/04/16/monotonic-painting.html
]]
const function evaluate(node: graph.GraphNode, force_computation: boolean?): boolean
	if node.validity == "busy" then
		log_error(graph.infinite_loop)
	end

	const first_evaluation = node.cached_version == nil and node.absolute_version == nil
	const is_dirty = node.validity == "dirty"
	const is_invalid = node.validity == "invalid"

	if not (first_evaluation or is_dirty or is_invalid or force_computation) then
		return false
	end

	local needs_computation = force_computation or first_evaluation or is_dirty

	-- check dependencies to see if any of them have updated before use, if so then we need to be reevaluated
	if not needs_computation then
		for dependency in node.using do
			evaluate(dependency, false)

			if (dependency.cached_version :: number) > (node.absolute_version :: number) then
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

		meaningfully_changed = node:evaluate() or first_evaluation

		node.absolute_version = next_version()

		if meaningfully_changed then
			node.cached_version = node.absolute_version
		end
	end

	node.validity = "valid"

	return meaningfully_changed
end

return evaluate
