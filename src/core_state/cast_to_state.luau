--!strict
--!native
--optimize 2

const state = require("./types")

const xtypeof = require("../core_graph/xtypeof")

const function cast_to_state(x: any): state.StateNode<unknown>?
	if xtypeof(x) == "state" then
		return x
	end

	return nil
end

return cast_to_state
