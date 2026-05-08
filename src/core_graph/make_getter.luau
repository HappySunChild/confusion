local graph = require("./types")

local function make_getter<T>(raw: graph.rawgetter<T>): graph.usegetter<T>
	local getter = {
		type = "getter",
		raw = raw,
	}

	return getter
end

return make_getter
