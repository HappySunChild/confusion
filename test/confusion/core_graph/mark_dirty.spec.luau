local butler = require("@butler/butler")

local GraphNode = require("@utility/GraphNode")
local cleanup = require("@fusion/core_memory/cleanup")
local mark_dirty = require("@fusion/core_graph/mark_dirty")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("mark_dirty", function(test: butler.Test)
		test("lazy", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(node.validity):to_equal("valid")
			mark_dirty(node)
			expect(node.validity):to_equal("dirty")
			cleanup(scope)
		end)
		test("eager", function()
			local scope = {}
			local node = GraphNode(scope, { timeliness = "eager" })

			expect(node.validity):to_equal("valid")
			mark_dirty(node)
			expect(node.validity):to_equal("valid")
			cleanup(scope)
		end)
	end)
end
