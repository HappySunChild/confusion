local butler = require("@butler/butler")

local GraphNode = require("@utility/GraphNode")
local cleanup = require("@fusion/core_memory/cleanup")
local is_eager = require("@fusion/core_graph/is_eager")
local observe = require("@fusion/core_graph/observe")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("is_eager", function(test: butler.Test)
		test("non-eager node", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(is_eager(node)):to_equal(false)

			cleanup(scope)
		end)
		test("non-eager node with observers", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(is_eager(node)):to_equal(false)

			observe(scope, node, function() end)

			expect(is_eager(node)):to_equal(true)

			cleanup(scope)
		end)
		test("eager node", function()
			local scope = {}
			local node = GraphNode(scope, { timeliness = "eager" })

			expect(is_eager(node)):to_equal(true)

			cleanup(scope)
		end)
		test("eager node with observers", function()
			local scope = {}
			local node = GraphNode(scope, { timeliness = "eager" })

			expect(is_eager(node)):to_equal(true)

			observe(scope, node, function() end)

			expect(is_eager(node)):to_equal(true)

			cleanup(scope)
		end)
	end)
end
