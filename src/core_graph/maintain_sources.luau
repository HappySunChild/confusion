local graph = require("./types")

local function maintain_sources(source_set: graph.Set<graph.source>, observer: graph.observer)
	for source in source_set do
		source(observer)
	end
end

return maintain_sources
