local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("peek", function(test: butler.Test)
		test("nonstate", function()
			expect(peek(nil)):to_equal(nil)
			expect(peek(1)):to_equal(1)
			expect(peek("foo")):to_equal("foo")

			local t = { foo = "bar" }
			expect(peek(t)):to_equal(t)
		end)
		test("state", function()
			local scope = {}

			local val = Value(scope, nil)
			expect(peek(val)):to_equal(nil)
			val:set(1)
			expect(peek(val)):to_equal(1)
			val:set("foo")
			expect(peek(val)):to_equal("foo")
			local t = { foo = "bar" }
			val:set(t)
			expect(peek(val)):to_equal(t)

			cleanup(scope)
		end)
	end)
end
