local graph = require("./types")

local change = require("./change")
local is_eager = require("./is_eager")
local log_error = require("../core_logging/log_error")

--[[
	Marks a graph node as "dirty", meaning it should be re-evaluated
	as soon as possible. If it is eager, then the node is immediately re-evaluated.
]]
local function mark_dirty(node: graph.GraphNode)
	if node.validity == "busy" then
		log_error(graph.infinite_loop)
	elseif node.validity == "dirty" then
		return false
	end

	if is_eager(node) then
		return change(node)
	end

	node.validity = "dirty"

	return false
end

return mark_dirty
