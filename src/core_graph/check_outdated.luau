local graph = require("./types")

local function check_outdated(sources: graph.Set<graph.source>, current_version: number): boolean
	if current_version == -1 then
		return true
	end

	for other_source in sources do
		if other_source() > current_version then
			return true
		end
	end

	return false
end

return check_outdated
