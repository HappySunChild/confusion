local butler = require("@butler/butler")

local GraphNode = require("@utility/GraphNode")
local change = require("@fusion/core_graph/change")
local cleanup = require("@fusion/core_memory/cleanup")
local observe_immediate = require("@fusion/core_graph/observe_immediate")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("observe_immediate", function(test: butler.Test)
		test("always fires on call", function()
			local scope = {}

			local ran = false
			local function dummy()
				ran = true
			end
			local disconnect = observe_immediate(scope, 123, dummy)

			expect(ran):to_equal(true)
			expect(disconnect):to_never_exist()
			expect(scope[1]):to_never_exist()
		end)
		test("connect and disconnect", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(node._observers):to_never_exist()

			local ran = false
			local function dummy()
				ran = true
			end
			local disconnect = observe_immediate(scope, node, dummy)

			expect(ran):to_equal(true)
			expect(node._observers):to_be_a("table")
			expect(node._observers[1]):to_equal(dummy)
			expect(scope[2]):to_equal(disconnect)

			disconnect()

			expect(node._observers[1]):to_never_exist()
			expect(scope[2]):to_never_exist()

			cleanup(scope)
		end)
		test("triggers while connected", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(node._observers):to_never_exist()

			local count = 0
			local function increment()
				count += 1
			end
			local disconnect = observe_immediate(scope, node, increment)

			expect(count):to_equal(1)
			change(node)
			expect(count):to_equal(2)
			change(node)
			expect(count):to_equal(3)

			disconnect()

			change(node)
			expect(count):to_equal(3)
			change(node)
			expect(count):to_equal(3)

			cleanup(scope)
		end)
	end)
end
