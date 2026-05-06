local state = require("../core_calc/types")

local function peek<T>(value: state.UsedAs<T>): T
	return if type(value) == "function" then value() else value
end

return peek
