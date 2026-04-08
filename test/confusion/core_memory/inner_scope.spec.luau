local butler = require("@butler/butler")

local inner_scope = require("@fusion/core_memory/inner_scope")
local scoped = require("@fusion/core_memory/scoped")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("inner_scope", function(test: butler.Test)
		test("base with no metatable, no methods", function()
			local base = {}
			local inner = inner_scope(base)
			local inner_meta = getmetatable(inner)

			expect(base[1]):to_equal(inner)

			expect(inner):to_be_a("table")
			expect(inner[1]):to_be_a("function")

			expect(inner_meta):to_never_exist()
		end)
		test("base with no metatable, with methods", function()
			local base = {}
			local methods = { foo = "bar" }
			local inner = inner_scope(base, methods)
			local inner_meta = getmetatable(inner)

			expect(base[1]):to_equal(inner)

			expect(inner):to_be_a("table")
			expect(inner[1]):to_be_a("function")
			expect(inner.foo):to_equal("bar")

			expect(inner_meta):to_be_a("table")
			expect(inner_meta.__index):to_equal(methods)
		end)
		test("base with metatable, no methods", function()
			local base = scoped({ foo = "bar" })
			local inner = inner_scope(base)
			local base_meta = getmetatable(base)
			local inner_meta = getmetatable(inner)

			expect(base[1]):to_equal(inner)

			expect(inner):to_be_a("table")
			expect(inner[1]):to_be_a("function")
			expect(inner.foo):to_equal("bar")

			expect(inner_meta):to_equal(base_meta)
		end)
		test("base with metatable, with methods", function()
			local base = scoped({ foo = "bar" })
			local methods = { baz = "qux" }
			local inner = inner_scope(base, methods)
			local base_meta = getmetatable(base)
			local inner_meta = getmetatable(inner)

			expect(base[1]):to_equal(inner)

			expect(inner):to_be_a("table")
			expect(inner[1]):to_be_a("function")
			expect(inner.foo):to_equal("bar")
			expect(inner.baz):to_equal("qux")

			expect(inner_meta):to_be_a("table")
			expect(inner_meta.__index)
				:to_be_a("table")
				:to_never_equal(base_meta)
				:to_never_equal(methods)
			expect(inner_meta.__index.foo):to_equal("bar")
			expect(inner_meta.__index.baz):to_equal("qux")
		end)
		test("methods override base with metatable", function()
			local base = scoped({ foo = "bar" })
			local methods = { foo = "qux" }
			local inner = inner_scope(base, methods)
			local base_meta = getmetatable(base)
			local inner_meta = getmetatable(inner)

			expect(base[1]):to_equal(inner)

			expect(inner):to_be_a("table")
			expect(inner[1]):to_be_a("function")
			expect(inner.foo):to_equal("qux")

			expect(inner_meta):to_be_a("table")
			expect(inner_meta.__index)
				:to_be_a("table")
				:to_never_equal(base_meta)
				:to_never_equal(methods)
			expect(inner_meta.__index.foo):to_equal("qux")
		end)
	end)
end
