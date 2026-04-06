local butler = require("@butler/butler")

local GraphNode = require("@utility/GraphNode")
local change = require("@fusion/core_graph/change")
local cleanup = require("@fusion/core_memory/cleanup")
local observe = require("@fusion/core_graph/observe")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("observe", function(test: butler.Test)
		local function dummy() end

		test("constants", function()
			local scope = {}

			local disconnect = observe(scope, 123, dummy)

			expect(disconnect):to_never_exist()
			expect(scope[1]):to_never_exist()
		end)
		test("connects and disconnects", function()
			local scope = {}
			local node = GraphNode(scope)

			expect(node._observers):to_never_exist()

			local disconnect = observe(scope, node, dummy)

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
			local disconnect = observe(scope, node, increment)

			expect(count):to_equal(0)
			change(node)
			expect(count):to_equal(1)
			change(node)
			expect(count):to_equal(2)

			disconnect()

			change(node)
			expect(count):to_equal(2)
			change(node)
			expect(count):to_equal(2)

			cleanup(scope)
		end)
	end)
end
