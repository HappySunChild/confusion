--!strict
local graph = require("@fusion/core_graph/types")
local memory = require("@fusion/core_memory/types")

local destructor = require("@fusion/core_memory/destructor")

local CLASS = table.freeze({
	timeliness = "lazy",
	type = "graph",

	_evaluate = function()
		return true
	end,
})
local METATABLE = table.freeze({ __index = CLASS })

type Options = {
	timeliness: graph.Timeliness?,
	evaluate: ((graph.GraphNode) -> boolean)?,

	can_be_used: boolean?,
	can_use: boolean?,
}

local function GraphNode(scope: memory.Scope, options: Options?): graph.GraphNode
	local new_graphnode: graph.GraphNode = setmetatable({
		scope = scope,
		created_at = os.clock(),
		validity = "valid",
		timeliness = if options ~= nil then options.timeliness else nil,
		_evaluate = if options ~= nil then options.evaluate else nil,

		users = {},
		using = {},
	}, METATABLE) :: any

	if options and options.can_be_used == false then
		table.freeze(new_graphnode.users)
	end

	if options and options.can_use == false then
		table.freeze(new_graphnode.using)
	end

	local oldest_task = destructor(new_graphnode)
	new_graphnode._oldest_task = oldest_task

	table.insert(scope, oldest_task)

	return new_graphnode
end

return GraphNode
