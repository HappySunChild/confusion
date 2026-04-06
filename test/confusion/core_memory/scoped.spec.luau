local butler = require("@butler/butler")

local scoped = require("@fusion/core_memory/scoped")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("scoped", function(test: butler.Test)
		test("no base, no methods", function()
			local scope = scoped()
			local meta = getmetatable(scope)

			expect(scope):to_be_a("table")
			expect(next(scope)):to_never_exist()

			expect(meta):to_never_exist()
		end)
		test("no base, with methods", function()
			local methods = { baz = "qux" }
			local scope = scoped(nil, methods)
			local meta = getmetatable(scope)

			expect(scope):to_be_a("table")
			expect(next(scope)):to_never_exist()
			expect(scope.baz):to_equal("qux")

			expect(meta):to_be_a("table")
			expect(meta.__index):to_equal(methods)
		end)
		test("with base, no methods", function()
			local base = { foo = "bar" }
			local scope = scoped(base)
			local meta = getmetatable(scope)

			expect(scope):to_be_a("table")
			expect(next(scope)):to_never_exist()
			expect(scope.foo):to_equal("bar")

			expect(meta):to_be_a("table")
			expect(meta.__index):to_equal(base)
		end)
		test("with base, with methods", function()
			local base = { foo = "bar" }
			local methods = { baz = "qux" }
			local scope = scoped(base, methods)
			local meta = getmetatable(scope)

			expect(scope):to_be_a("table")
			expect(next(scope)):to_never_exist()
			expect(scope.foo):to_equal("bar")
			expect(scope.baz):to_equal("qux")

			expect(meta):to_be_a("table")
			expect(meta.__index):to_be_a("table"):to_never_equal(base):to_never_equal(methods)
			expect(meta.__index.foo):to_equal("bar")
			expect(meta.__index.baz):to_equal("qux")
		end)
		test("methods override base", function()
			local base = { foo = "bar" }
			local methods = { foo = "qux" }
			local scope = scoped(base, methods)
			local meta = getmetatable(scope)

			expect(scope):to_be_a("table")
			expect(next(scope)):to_never_exist()
			expect(scope.foo):to_equal("qux")

			expect(meta):to_be_a("table")
			expect(meta.__index):to_be_a("table"):to_never_equal(base):to_never_equal(methods)
			expect(meta.__index.foo):to_equal("qux")
		end)
	end)
end
