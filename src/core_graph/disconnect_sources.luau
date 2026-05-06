local graph = require("./types")

local function disconnect_sources(sources: graph.Set<graph.source>, observer: graph.observer)
	for source in sources do
		source(observer, true)
	end

	table.clear(sources)
end

return disconnect_sources
