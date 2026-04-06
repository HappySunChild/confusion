local Computed = require("@fusion/core_calc/Computed")
local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local generic_use = require("@fusion/core_use/generic_use")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("generic_use", function(test: butler.Test)
		test("constructing", function()
			local scope = {}
			local node = Computed(scope, function() end)
			local use = generic_use(node)

			expect(use):to_be_a("function")

			cleanup(scope)
		end)
		test("use", function()
			local scope = {}
			local node_a = Computed(scope, function() end)
			local use = generic_use(node_a) -- todo: not this

			expect(use(nil)):to_equal(nil)
			expect(use(1)):to_equal(1)
			expect(use("foo")):to_equal("foo")
			local t = { foo = "bar" }
			expect(use(t)):to_equal(t)

			local node_b = Value(scope, "foo")
			expect(use(node_b)):to_equal("foo")

			expect(node_a.using[node_b]):to_exist()
			expect(node_b.users[node_a]):to_exist()

			cleanup(scope)
		end)
	end)
end
