local ForValues = require("@fusion/iter_for/ForValues")
local Value = require("@fusion/core_state/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForValues", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forvalues = ForValues(scope, {}, function() end)
			expect(forvalues):to_have_pairs({ type = "state", kind = "Iter" })
			expect(scope):to_have_value(forvalues._oldest_task)
			cleanup(scope)
		end)
		test("iterates, constants", function()
			local scope = {}
			local data = { "foo", "bar" }
			local forvalues = ForValues(scope, data, function(_, _, value: string)
				return string.upper(value)
			end)
			expect(peek(forvalues)):to_have_pairs({ "FOO", "BAR" })
			cleanup(scope)
		end)
		test("iterates, state", function()
			local scope = {}
			local data = Value(scope, { "foo", "bar" })
			local forvalues = ForValues(scope, data, function(_, _, value: string)
				return string.upper(value)
			end)
			expect(peek(forvalues)):to_have_pairs({ "FOO", "BAR" })
			data:set({ "baz", "qux" })
			expect(peek(forvalues))
				:to_never_have_values({ "FOO", "BAR" })
				:to_have_pairs({ "BAZ", "QUX" })
			cleanup(scope)
		end)
		test("use, constants", function()
			local scope = {}
			local data = { "foo", "bar" }
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				return value .. use("baz")
			end)
			expect(peek(forvalues)):to_have_pairs({ "foobaz", "barbaz" })
			cleanup(scope)
		end)
		test("use, state", function()
			local scope = {}
			local data = { "foo", "bar" }
			local suffix = Value(scope, "first")
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				return value .. use(suffix)
			end)
			expect(peek(forvalues)):to_have_pairs({ "foofirst", "barfirst" })
			suffix:set("second")
			expect(peek(forvalues)):to_have_pairs({ "foosecond", "barsecond" })
			cleanup(scope)
		end)
		test("errors", function()
			local scope = {}
			local data = { "foo", "bar", "baz" }
			local suffix = Value(scope, "first")
			local destroyed = {}
			local forvalues = ForValues(scope, data, function(use, inner_scope, value: string)
				local generated = value .. use(suffix)
				table.insert(inner_scope, function()
					destroyed[generated] = true
				end)
				if value == "bar" and use(suffix) == "second" then
					error("This is an intentional error from a unit test")
				end
				return generated
			end)
			expect(peek(forvalues)):to_have_pairs({ "foofirst", "barfirst", "bazfirst" })
			suffix:set("second")
			expect(peek(forvalues))
				:to_never_have_values({ "foofirst", "barfirst", "bazfirst" })
				:to_never_have_key(3)
				:to_have_pairs({ "foosecond", "bazsecond" })
			expect(destroyed)
				:to_never_have_keys({ "foosecond", "bazsecond" })
				:to_have_keys({ "foofirst", "barfirst", "bazfirst", "barsecond" })
			suffix:set("third")
			expect(peek(forvalues))
				:to_never_have_values({
					"foofirst",
					"barfirst",
					"bazfirst",
					"foosecond",
					"barsecond",
					"bazsecond",
				})
				:to_have_pairs({ "foothird", "barthird", "bazthird" })
			expect(destroyed):to_have_keys({
				"foofirst",
				"barfirst",
				"bazfirst",
				"foosecond",
				"barsecond",
				"bazsecond",
			})
			cleanup(scope)
		end)
		test("nil", function()
			local scope = {}
			local data = { "foo", "bar", "baz" }
			local omit_third = Value(scope, false)
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				if value == "bar" then
					return nil
				end
				if use(omit_third) and value == "baz" then
					return nil
				end
				return value
			end)
			expect(peek(forvalues)):to_never_have_keys({ 3 }):to_have_pairs({ "foo", "baz" })
			omit_third:set(true)
			expect(peek(forvalues)):to_never_have_keys({ 2, 3 }):to_have_pairs({ "foo" })
			omit_third:set(false)
			expect(peek(forvalues)):to_never_have_keys({ 3 }):to_have_pairs({ "foo", "baz" })
			cleanup(scope)
		end)
		test("cleanup, state change", function()
			local scope = {}
			local destructed = {}
			local data = Value(scope, { "foo", "bar" })
			local forvalues = ForValues(scope, data, function(_, inner_scope, value)
				table.insert(inner_scope, function()
					destructed[value] = true
				end)
				return value
			end)
			peek(forvalues)
			expect(destructed):to_never_have_keys({ "foo", "bar", "baz" })
			data:set({ "baz" })
			peek(forvalues)
			expect(destructed):to_have_keys({ "foo", "bar" }):to_never_have_key("baz")
			cleanup(scope)
		end)
		test("cleanup, external cleanup", function()
			local scope = {}
			local destructed = {}
			local data = { "foo", "bar" }
			local forvalues = ForValues(scope, data, function(_, inner_scope, value)
				table.insert(inner_scope, function()
					destructed[value] = true
				end)
				return value
			end)
			peek(forvalues)
			expect(destructed):to_be_empty()
			cleanup(scope)
			expect(destructed):to_have_keys({ "foo", "bar" })
		end)
		test("order", function()
			local scope = {}
			local data = Value(scope, { "10", "20", "30", "40", "50" })
			local omit = Value(scope, {})
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				if table.find(use(omit), value) ~= nil then
					return nil
				end

				return value
			end)
			expect(peek(forvalues)):to_have_pairs({ "10", "20", "30", "40", "50" })
			data:set({ "50", "40", "30", "20", "10" })
			expect(peek(forvalues)):to_have_pairs({ "50", "40", "30", "20", "10" })
			data:set({ "50", "30", "10", "40" })
			expect(peek(forvalues)):to_have_pairs({ "50", "30", "10", "40" }):to_never_have_key(5)
			omit:set({ "30" })
			expect(peek(forvalues)):to_have_pairs({ "50", "10", "40" }):to_never_have_keys({ 4, 5 })
			data:set({ "10", "20", "30", "40", "50" })
			expect(peek(forvalues)):to_have_pairs({ "10", "20", "40", "50" }):to_never_have_key(5)
			cleanup(scope)
		end)
		test("roaming values", function()
			local scope = {}
			local data = Value(scope, { "foo", "bar" })
			local computations = 0
			local forvalues = ForValues(scope, data, function(_, _, value: string)
				computations += 1
				return string.upper(value)
			end)
			peek(forvalues)
			expect(computations):to_equal(2)
			data:set({ "bar", "foo" })
			peek(forvalues)
			expect(computations):to_equal(2)
			data:set({ "foo", "bar", "baz" })
			peek(forvalues)
			expect(computations):to_equal(3)
			data:set({ "qux" })
			peek(forvalues)
			expect(computations):to_equal(4)
			cleanup(scope)
		end)
	end)
end
