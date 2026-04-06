local calc = require("../core_calc/types")
local graph = require("../core_graph/types")
local use = require("./types")

local cast_to_state = require("../core_calc/cast_to_state")
local depend = require("../core_graph/depend")
local log_error = require("../core_logging/log_error")
local peek = require("./peek")

local function generic_use(user: graph.GraphNode): calc.Use
	if cast_to_state(user) == nil then
		log_error(use.invalid_user, nil, typeof(user), user)
	end

	local function use<T>(target: calc.UsedAs<T>): T
		depend(user, target)
		return peek(target)
	end

	return use
end

return generic_use
