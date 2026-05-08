local graph = require("./types")

local function notify_observers(observer_set: graph.Set<graph.observer>)
	for observer in observer_set do
		observer()
	end

	table.clear(observer_set)
end

return notify_observers
