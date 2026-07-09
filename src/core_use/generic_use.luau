const graph = require("../core_graph/types")
const state = require("../core_state/types")
const use = require("./types")

const ExternalLogger = require("../core_external/ExternalLogger")
const log_error = ExternalLogger.log_error

const cast_to_graph = require("../core_graph/cast_to_graph")
const depend = require("../core_graph/depend")
const peek = require("./peek")

const function generic_use(user: graph.GraphNode): state.Use
	if cast_to_graph(user) == nil then
		log_error(use.invalid_user, nil, typeof(user), user)
	end

	const function use<T>(target: state.UsedAs<T>): T
		depend(user, target)
		return peek(target)
	end

	return use
end

return generic_use
