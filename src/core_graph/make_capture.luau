local graph = require("./types")

local function make_capture(source_set: graph.Set<graph.source>, observer: graph.observer): graph.capture
	local function capture(using_source: graph.source)
		source_set[using_source] = true
		return observer
	end

	return capture
end

return make_capture
