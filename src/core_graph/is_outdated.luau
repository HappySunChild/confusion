local graph = require("./types")

--- Returns whether a version is outdated based off of a provided set of sources.
local function is_outdated(version: number, source_set: graph.Set<graph.source>): boolean
	if version == -1 then
		return true
	end

	for other_source in source_set do
		if other_source() > version then
			return true
		end
	end

	return false
end

return is_outdated
