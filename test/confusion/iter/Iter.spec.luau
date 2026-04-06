local Iter = require("@fusion/iter/Iter")
local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("Iter", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local iter = Iter(scope, nil)

			expect(iter):to_be_a("table")
			expect(iter._cached_value):to_be_a("table")
			expect(iter.type):to_equal("state")
			expect(iter.kind):to_equal("Iter")
			expect(scope):to_have_value(iter._oldest_task)

			cleanup(scope)
		end)
		test("populates", function()
			local scope = {}

			local test_pairs = Value(scope, { foo = "bar" })
			local iter = Iter(scope, {
				scope = scope,
				users = {},
				using = {},
				populate = function(self, use, output)
					for k, v in use(test_pairs) do
						output[k] = v
					end
				end,
				_evaluate = function()
					return true
				end,
			})

			expect(peek(iter).foo):to_equal("bar")
			expect(peek(iter).bar):to_never_exist()
			test_pairs:set({
				foo = "bar",
				bar = "foo",
			})
			expect(peek(iter).foo):to_equal("bar")
			expect(peek(iter).bar):to_equal("foo")
			test_pairs:set({})
			expect(peek(iter).foo):to_never_exist()
			expect(peek(iter).bar):to_never_exist()
			cleanup(scope)
		end)
	end)
end
