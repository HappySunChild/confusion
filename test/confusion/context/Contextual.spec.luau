local Contextual = require("@fusion/context/Contextual")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("Contextual", function(test: butler.Test)
		test("constructs", function()
			local context = Contextual(nil)

			expect(context):to_be_a("table")
			expect(context.type):to_equal("Contextual")
		end)
		test("default", function()
			local context = Contextual("foo")

			expect(context:now()):to_equal("foo")
		end)
		test("scoped values", function()
			local context = Contextual("foo")

			expect(context:now()):to_equal("foo")

			context:execute_with("bar", function()
				expect(context:now()):to_equal("bar")

				context:execute_with("baz", function()
					expect(context:now()):to_equal("baz")
				end)

				expect(context:now()):to_equal("bar")
			end)

			expect(context:now()):to_equal("foo")
		end)
		test("arguments", function()
			local context = Contextual("foo")

			local function test(a, b, c, d)
				expect(a):to_equal("a")
				expect(b):to_equal("b")
				expect(c):to_equal("c")
				expect(d):to_equal("d")
			end

			context:execute_with("baz", test, "a", "b", "c", "d")
		end)
		test("thread safe", function()
			local context = Contextual("foo")

			local thread_a = coroutine.create(function()
				context:is("bar"):during(function()
					expect(context:now()):to_equal("bar")
					coroutine.yield()
					expect(context:now()):to_equal("bar")
				end)
			end)

			local thread_b = coroutine.create(function()
				context:is("baz"):during(function()
					expect(context:now()):to_equal("baz")
					coroutine.yield()
					expect(context:now()):to_equal("baz")
				end)
			end)

			coroutine.resume(thread_a)
			expect(context:now()):to_equal("foo")
			coroutine.resume(thread_b)
			expect(context:now()):to_equal("foo")
			coroutine.resume(thread_a)
			expect(context:now()):to_equal("foo")
			coroutine.resume(thread_b)
			expect(context:now()):to_equal("foo")
		end)
	end)
end
