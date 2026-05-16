const memory = require("../core_memory/types")

const ExternalScheduler = require("../core_external/ExternalScheduler")
const do_task_immediate = ExternalScheduler.do_task_immediate

const observe = require("./observe")

--[[
	Adds an observer callback to a graph node after immediately calling the callback.
	This has the side effect of also making the node eager.
	
	Returns a disconnect function that removes the observer callback from the node.
]]
const function observe_immediate(scope: memory.Scope, subject: any, callback: () -> ()): (() -> ())?
	do_task_immediate(callback)

	return observe(scope, subject, callback)
end

return observe_immediate
