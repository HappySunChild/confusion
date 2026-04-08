local butler = require("@butler/butler")

local derive_scope = require("@fusion/core_memory/derive_scope")
local scoped = require("@fusion/core_memory/scoped")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("derive_scope", function(test: butler.Test)
		test("base with no metatable, no methods", function()
			local base_scope = {}
			local derived_scope = derive_scope(base_scope)
			local derived_meta = getmetatable(derived_scope)

			expect(derived_scope):to_be_a("table")
			expect(next(derived_scope)):to_never_exist()

			expect(derived_meta):to_never_exist()
		end)
		test("base with no metatable, with methods", function()
			local base_scope = {}
			local methods = { foo = "bar" }
			local derived_scope = derive_scope(base_scope, methods)
			local derived_meta = getmetatable(derived_scope)

			expect(derived_scope):to_be_a("table")
			expect(next(derived_scope)):to_never_exist()
			expect(derived_scope.foo):to_equal("bar")

			expect(derived_meta):to_be_a("table")
			expect(derived_meta.__index):to_equal(methods)
		end)
		test("base with metatable, no methods", function()
			local base_scope = scoped({ foo = "bar" })
			local derived_scope = derive_scope(base_scope)
			local base_meta = getmetatable(base_scope)
			local derived_meta = getmetatable(derived_scope)

			expect(derived_scope):to_be_a("table")
			expect(next(derived_scope)):to_never_exist()
			expect(derived_scope.foo):to_equal("bar")

			expect(derived_meta):to_equal(base_meta)
		end)
		test("base with metatable, with methods", function()
			local base_scope = scoped({ foo = "bar" })
			local methods = { baz = "qux" }
			local derived_scope = derive_scope(base_scope, methods)
			local base_meta = getmetatable(base_scope)
			local derived_meta = getmetatable(derived_scope)

			expect(derived_scope):to_be_a("table")
			expect(next(derived_scope)):to_never_exist()
			expect(derived_scope.foo):to_equal("bar")
			expect(derived_scope.baz):to_equal("qux")

			expect(derived_meta):to_be_a("table")
			expect(derived_meta.__index)
				:to_be_a("table")
				:to_never_equal(base_meta)
				:to_never_equal(methods)
			expect(derived_meta.__index.foo):to_equal("bar")
			expect(derived_meta.__index.baz):to_equal("qux")
		end)
		test("methods override base with metatable", function()
			local base_scope = scoped({ foo = "bar" })
			local methods = { foo = "qux" }
			local derived_scope = derive_scope(base_scope, methods)
			local base_meta = getmetatable(base_scope)
			local derived_meta = getmetatable(derived_scope)

			expect(derived_scope):to_be_a("table")
			expect(next(derived_scope)):to_never_exist()
			expect(derived_scope.foo):to_equal("qux")

			expect(derived_meta):to_be_a("table")
			expect(derived_meta.__index)
				:to_be_a("table")
				:to_never_equal(base_meta)
				:to_never_equal(methods)
			expect(derived_meta.__index.foo):to_equal("qux")
		end)
	end)
end
