local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("Value", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local value = Value(scope, nil)

			expect(value):to_be_a("table")
			expect(value.type):to_equal("state")
			expect(value.kind):to_equal("Value")
			expect(scope):to_have_value(value._oldest_task)

			cleanup(scope)
		end)
		test("default", function()
			local scope = {}
			local value = Value(scope, 5)
			expect(peek(value)):to_equal(5)
			cleanup(scope)
		end)
		test("settable", function()
			local scope = {}
			local value = Value(scope, 0)
			expect(peek(value)):to_equal(0)

			value:set(10)
			expect(peek(value)):to_equal(10)

			value:set("foo")
			expect(peek(value)):to_equal("foo")

			cleanup(scope)
		end)
		test("updates last_change on set", function()
			local scope = {}
			local value = Value(scope, 1)

			local before = value.last_change
			value:set(2)
			expect(value.last_change):to_never_equal(before)

			before = value.last_change
			value:set(3)
			expect(value.last_change):to_never_equal(before)

			before = value.last_change
			value:set("foo")
			expect(value.last_change):to_never_equal(before)

			cleanup(scope)
		end)
		test("doesn't update last_change on similar sets", function()
			local scope = {}
			local value = Value(scope, 1)

			local before = value.last_change
			value:set(2)
			expect(value.last_change):to_never_equal(before)

			before = value.last_change
			value:set(2)
			expect(value.last_change):to_equal(before)

			cleanup(scope)
		end)
		test("validity", function()
			local scope = {}
			local value = Value(scope, 1)
			expect(value.validity):to_equal("valid")

			value:set(2)
			expect(value.validity):to_equal("valid")

			value:set(3)
			expect(value.validity):to_equal("valid")

			value:set(4)
			expect(value.validity):to_equal("valid")

			cleanup(scope)
		end)
		test("returns set", function()
			local scope = {}
			local value = Value(scope, 0)

			local foo = value:set(10)
			expect(foo):to_equal(10)

			local bar = value:set(10)
			expect(bar):to_equal(10)

			local baz = value:set(25)
			expect(baz):to_equal(25)

			local garb = value:set(25)
			expect(garb):to_equal(25)

			cleanup(scope)
		end)
	end)
end
