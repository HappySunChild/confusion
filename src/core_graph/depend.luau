local graph = require("./types")

local cast_to_graph = require("./cast_to_graph")
local check_lifetime = require("../core_memory/check_lifetime")
local evaluate = require("./evaluate")
local log_error = require("../core_logging/log_error")
local name_of = require("../core_logging/name_of")

local function depend_lifetime_formatter(a: unknown, b: unknown): (string, string)
	return `The dependency '{name_of(b, "object")}'`,
		`being used by the user '{name_of(a, "object")}'`
end

local function depend(user: graph.GraphNode, dependency: any?)
	if cast_to_graph(dependency) == nil then
		return
	end

	if cast_to_graph(user) == nil then
		return
	end

	check_lifetime(user, dependency, dependency.scope, depend_lifetime_formatter)

	evaluate(dependency)

	if table.isfrozen(user.using) then
		log_error(
			graph.cannot_depend_user_frozen,
			nil,
			name_of(user, "unknown"),
			name_of(dependency, "unknown")
		)
	elseif table.isfrozen(dependency.users) then
		log_error(
			graph.cannot_depend_dependency_frozen,
			nil,
			name_of(user, "unknown"),
			name_of(dependency, "unknown")
		)
	end

	user.using[dependency] = true
	dependency.users[user] = true
end

return depend
