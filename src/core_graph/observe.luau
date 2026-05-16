const memory = require("../core_memory/types")

const name_of = require("../core_logging/name_of")
const nicknames = require("../core_logging/nicknames")

const check_lifetime = require("../core_memory/check_lifetime")

const cast_to_graph = require("./cast_to_graph")
const evaluate = require("./evaluate")

const function observe_lifetime_formatter(_, b: unknown)
	return `The subject '{name_of(b, "unknown")}'`, "it could be observed"
end

--[[
	Adds an observer callback to a graph node. This has the side 
	effect of also making the node eager.
	
	Returns a disconnect function that removes the observer callback from the node.
]]
const function observe(scope: memory.Scope, subject: any, callback: () -> ()): (() -> ())?
	if cast_to_graph(subject) == nil then
		return nil
	end

	check_lifetime(nil, subject, subject.scope, observe_lifetime_formatter)

	local observers = subject._observers :: { () -> () }

	if observers == nil then
		observers = {}
		subject._observers = observers
	end

	table.insert(observers, callback)

	evaluate(subject)

	const function disconnect()
		const observe_index = table.find(observers, callback)

		if observe_index ~= nil then
			table.remove(observers, observe_index)
		end

		const disconnect_index = table.find(scope, disconnect)

		if disconnect_index ~= nil then
			table.remove(scope, disconnect_index)
		end
	end

	nicknames[disconnect] = `Observer ({name_of(subject, "unknown")})`

	table.insert(scope, disconnect)

	return disconnect
end

return observe
