local Computed = require("@fusion/core_calc/Computed")
local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("Computed", function(test: butler.Test)
		test("dissolves with constants", function()
			local scope = {}
			local computed = Computed(scope, function(use)
				return use("foo")
			end)

			expect(computed):to_be_a("string"):to_equal("foo")
			expect(scope):to_never_have_key(1)

			cleanup(scope)
		end)
		test("constructs with state", function()
			local scope = {}
			local value = Value(scope, 0)
			local computed = Computed(scope, function(use)
				return use(value)
			end)

			expect(computed):to_be_a("table")
			expect(computed.type):to_equal("state")
			expect(computed.kind):to_equal("Computed")
			expect(scope):to_have_value(computed._oldest_task)

			cleanup(scope)
		end)
		test("destroy", function()
			local scope = {}
			local value = Value(scope)
			Computed(scope, function(use)
				use(value)
			end)
			expect(cleanup):to_never_throw(scope)
		end)
		test("computes", function()
			local scope = {}
			local dependency = Value(scope, 5)
			local computed = Computed(scope, function(use)
				return use(dependency)
			end)
			expect(peek(computed)):to_equal(5)
			dependency:set("foo")
			expect(peek(computed)):to_equal("foo")
			cleanup(scope)
		end)
		test("preserves", function()
			local scope = {}
			local dependency = Value(scope, 5)
			local computed = Computed(scope, function(use)
				assert(use(dependency) ~= 13, "This is an intentional error from a unit test")
				return use(dependency)
			end)
			expect(peek(computed)):to_equal(5)
			dependency:set(13) -- this will invoke the error
			expect(peek(computed)):to_equal(5)
			dependency:set(2)
			expect(peek(computed)):to_equal(2)
			cleanup(scope)
		end)
		-- test("doesn't destroy inner scope on creation", function()
		-- 	local scope = {}
		-- 	local destructed = false
		-- 	local computed = Computed(scope, function(_, inner)
		-- 		table.insert(inner, function()
		-- 			destructed = true
		-- 		end)
		-- 	end)
		-- 	peek(computed)
		-- 	expect(destructed):to_equal(false)

		-- 	cleanup(scope)
		-- end),
		test("cleanup innerscope on recompute", function()
			local scope = {}
			local destructed = {}
			local dependency = Value(scope, 1)
			local computed = Computed(scope, function(use, inner)
				local value = use(dependency)

				table.insert(inner, function()
					destructed[value] = true
				end)

				return use(dependency)
			end)
			peek(computed)
			expect(destructed[1]):to_equal(nil)
			dependency:set(2)
			peek(computed)
			expect(destructed[1]):to_equal(true)
			expect(destructed[2]):to_equal(nil)
			dependency:set(3)
			peek(computed)
			expect(destructed[2]):to_equal(true)

			cleanup(scope)
		end)
		test("destroys errored values and preserves the last non-error value", function()
			local scope = {}
			local num_destructions = {}
			local dependency = Value(scope, 1)
			local computed = Computed(scope, function(use, inner)
				local value = use(dependency)

				table.insert(inner, function()
					num_destructions[value] = (num_destructions[value] or 0) + 1
				end)

				assert(value ~= 2, "This is an intentional error from a unit test")
				return value
			end)
			peek(computed)
			expect(num_destructions[1]):to_equal(nil)
			dependency:set(2)
			peek(computed)
			expect(num_destructions[1]):to_equal(nil)
			expect(num_destructions[2]):to_equal(1)
			dependency:set(3)
			peek(computed)
			expect(num_destructions[2]):to_equal(1)
			expect(num_destructions[3]):to_equal(nil)
			dependency:set(4)
			peek(computed)
			expect(num_destructions[3]):to_equal(1)

			cleanup(scope)
		end)
		test("cleanup innerscope on cleanup", function()
			local scope = {}
			local destructed = false
			local dependency = Value(scope)
			local computed = Computed(scope, function(use, inner)
				use(dependency) -- to avoid getting dissolved into a constant

				table.insert(inner, function()
					destructed = true
				end)
			end)
			peek(computed)
			expect(destructed):to_equal(false)
			cleanup(scope)
			expect(destructed):to_equal(true)
		end)
		-- TODO: more tests related to dissolving
	end)
end
