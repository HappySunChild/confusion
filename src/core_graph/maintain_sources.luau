local graph = require("./types")

local function maintain_sources(sources: graph.Set<graph.source>, observer: graph.observer)
	for source in sources do
		source(observer)
	end
end

return maintain_sources
