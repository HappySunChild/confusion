local graph = require("./types")

local function schedule_observers(observers: graph.Set<graph.observer>)
	for observer in observers do
		observer()
	end

	table.clear(observers)
end

return schedule_observers
