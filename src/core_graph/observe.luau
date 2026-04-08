local graph = require("./types")
local memory = require("../core_memory/types")

local name_of = require("../core_logging/name_of")
local nicknames = require("../core_logging/nicknames")

local check_lifetime = require("../core_memory/check_lifetime")

local cast_to_graph = require("./cast_to_graph")
local evaluate = require("./evaluate")

local function observe_lifetime_formatter(_, b: unknown)
	return `The subject '{name_of(b)}'`, "it could be observed"
end

--[[
	Adds an observer callback to a graph node. This has the side 
	effect of also making the node eager.
	
	Returns a disconnect function that removes the observer callback from the node.
]]
local function observe(
	scope: memory.Scope,
	subject: graph.GraphNode,
	callback: () -> ()
): (() -> ())?
	if cast_to_graph(subject) == nil then
		return nil
	end

	check_lifetime(nil, subject, subject.scope, observe_lifetime_formatter)

	if subject._observers == nil then
		subject._observers = {}
	end

	table.insert(subject._observers, callback)

	evaluate(subject)

	local function disconnect()
		local observe_index = table.find(subject._observers, callback)

		if observe_index ~= nil then
			table.remove(subject._observers, observe_index)
		end

		local disconnect_index = table.find(scope, disconnect)

		if disconnect_index ~= nil then
			table.remove(scope, disconnect_index)
		end
	end

	nicknames[disconnect] = `Observer ({name_of(subject, "unknown")})`

	table.insert(scope, disconnect)

	return disconnect
end

return observe
