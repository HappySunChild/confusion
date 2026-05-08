local graph = require("./types")

local function disconnect_sources(source_set: graph.Set<graph.source>, observer: graph.observer)
	for source in source_set do
		source(observer, true)
	end

	table.clear(source_set)
end

return disconnect_sources
