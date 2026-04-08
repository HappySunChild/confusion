local graph = require("../core_graph/types")

--[[
	Returns `true` if a graph node is eager.
]]
local function is_eager(node: graph.GraphNode): boolean
	if node.timeliness == "eager" then
		return true
	end

	if node._observers ~= nil then
		return next(node._observers) ~= nil
	end

	return false
end

return is_eager
