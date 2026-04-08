local memory = require("./types")

local function insert<Tasks...>(scope: memory.Scope, ...: Tasks...): Tasks...
	for i = 1, select("#", ...) do
		table.insert(scope, (select(i, ...)))
	end

	return ...
end

return insert
