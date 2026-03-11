local async = require("./types")
local graph = require("../core_graph/types")
local memory = require("../core_memory/types")

local cast_to_graph = require("../core_graph/cast_to_graph")
local log_error = require("../core_logging/log_error")
local observe = require("../core_graph/observe")

-- Pauses the current thread until the subject receives an eager update
local function await(scope: memory.Scope, subject: graph.GraphNode)
	if cast_to_graph(subject) == nil then
		-- i believe this should error, because if we didn't it would infitely yield a thread
		-- or cause loops that depend on it to spiral out of control
		log_error(async.invalid_await_type, nil, typeof(subject))
	end

	local current = coroutine.running()

	local disconnect
	disconnect = observe(scope, subject, function()
		coroutine.resume(current)

		disconnect()
	end)

	coroutine.yield()
end

return await :: async.Await
