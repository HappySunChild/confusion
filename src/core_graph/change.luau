local graph = require("./types")

local ExternalScheduler = require("../core_external/ExternalScheduler")
local do_task_immediate = ExternalScheduler.do_task_immediate

local evaluate = require("./evaluate")
local is_eager = require("./is_eager")
local log_error = require("../core_logging/log_error")

local function fire_node_observers(node: graph.GraphNode)
	if node._observers == nil then
		return
	end

	for _, callback in node._observers do
		do_task_immediate(callback)
	end
end

--[[
	Prompts (forces) a graph node to be re-evaluated. If it meaningfully
	changes, then dependents will be marked invalid and will have to be
	re-evaluated at a later point (or immediately if it is eager).

	https://fluff.blog/2024/04/16/monotonic-painting.html
]]
local function change(node: graph.GraphNode)
	if not evaluate(node, true) then
		return false
	end

	local eager_users: { graph.GraphNode } = {}

	local search_now: { graph.GraphNode } = { node }
	local search_next: { graph.GraphNode } = {}

	repeat
		local is_finished = true

		for _, searching: graph.GraphNode in search_now do
			for user in searching.users do
				if user.validity == "busy" then
					log_error(graph.infinite_loop)
				elseif user.validity == "valid" then
					is_finished = false

					user.validity = "invalid"

					table.insert(search_next, user)

					if is_eager(user) then
						table.insert(eager_users, user)
					end
				end
			end
		end

		search_now, search_next = search_next, search_now
		table.clear(search_next)
	until is_finished

	table.sort(eager_users, function(x: graph.GraphNode, y: graph.GraphNode)
		return x.created_at < y.created_at
	end)

	fire_node_observers(node)

	for _, user: graph.GraphNode in eager_users do
		if evaluate(user) then
			fire_node_observers(user)
		end
	end

	return true
end

return change
