local graph = require("./types")

local function disconnect_observers(observer_set: graph.Set<graph.observer>, source: graph.source)
	for observer in observer_set do
		observer(source)
	end

	table.clear(observer_set)
end

return disconnect_observers
