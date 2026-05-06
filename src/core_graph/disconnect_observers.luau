local graph = require("./types")

local function disconnect_observers(observers: graph.Set<graph.observer>, source: graph.source)
	for observer in observers do
		observer(source)
	end

	table.clear(observers)
end

return disconnect_observers
