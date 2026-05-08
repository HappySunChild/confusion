local graph = require("./types")

local function cast_to_getter(x: unknown): graph.usegetter<any>
	return if type(x) == "table" and x.type == "getter" then x else nil
end

return cast_to_getter
