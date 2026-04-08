--!strict
local standard_graph_shapes = require("./standard_graph_shapes")

local function well_formed(shape: standard_graph_shapes.GraphShape)
	return shape.facts.well_formed
end

local function malformed(shape: standard_graph_shapes.GraphShape)
	return not shape.facts.well_formed
end

local filters = {
	well_formed = well_formed,
	malformed = malformed,
}

return filters
