local graph = require("./types")

local function make_capture(sources: graph.Set<graph.source>, observer: graph.observer): graph.capture
	local function capture(other: graph.source)
		sources[other] = true
		return observer
	end

	return capture
end

return make_capture
