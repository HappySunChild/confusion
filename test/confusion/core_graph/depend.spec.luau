local butler = require("@butler/butler")

local GraphNode = require("@utility/GraphNode")
local cleanup = require("@fusion/core_memory/cleanup")
local depend = require("@fusion/core_graph/depend")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("depend", function(test: butler.Test)
		test("graph <- non-graph", function()
			local scope = {}
			local user_node = GraphNode(scope)

			depend(user_node, 123)
			expect(next(user_node.using)):to_never_exist()

			depend(user_node, "foo")
			expect(next(user_node.using)):to_never_exist()

			depend(user_node, {})
			expect(next(user_node.using)):to_never_exist()

			cleanup(scope)
		end)
		test("graph <- graph", function()
			local scope = {}
			local user_node = GraphNode(scope)
			local dependency_node = GraphNode(scope)

			depend(user_node, dependency_node)
			expect(user_node.using[dependency_node]):to_equal(true)
			expect(dependency_node.users[user_node]):to_equal(true)

			cleanup(scope)
		end)
		test("graph <- unusable graph", function()
			local scope = {}
			local user_node = GraphNode(scope)
			local dependency_node = GraphNode(scope, { can_be_used = false })

			expect(depend):to_throw(user_node, dependency_node)
			expect(user_node.using[dependency_node]):to_never_exist()
			expect(dependency_node.users[user_node]):to_never_exist()

			cleanup(scope)
		end)
		test("no-use graph <- graph", function()
			local scope = {}
			local user_node = GraphNode(scope, { can_use = false })
			local dependency_node = GraphNode(scope)

			expect(depend):to_throw(user_node, dependency_node)
			expect(user_node.using[dependency_node]):to_never_exist()
			expect(dependency_node.users[user_node]):to_never_exist()

			cleanup(scope)
		end)
	end)
end
