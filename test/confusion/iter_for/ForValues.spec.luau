local ForValues = require("@fusion/iter_for/ForValues")
local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForValues", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forvalues = ForValues(scope, {}, function() end)

			expect(forvalues):to_be_a("table")
			expect(forvalues.type):to_equal("state")
			expect(forvalues.kind):to_equal("Iter")
			expect(scope):to_have_value(forvalues._oldest_task)

			cleanup(scope)
		end)
		test("iterates constants", function()
			local scope = {}
			local data = { "foo", "bar" }
			local forvalues = ForValues(scope, data, function(_, _, value: string)
				return string.upper(value)
			end)

			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("FOO")
			expect(peek(forvalues)[2]):to_equal("BAR")
			cleanup(scope)
		end)
		test("iterates state", function()
			local scope = {}
			local data = Value(scope, { "foo", "bar" })
			local forvalues = ForValues(scope, data, function(_, _, value: string)
				return string.upper(value)
			end)
			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("FOO")
			expect(peek(forvalues)[2]):to_equal("BAR")
			data:set({ "baz", "qux" })
			expect(peek(forvalues)):to_never_have_value("FOO"):to_never_have_value("BAR")
			expect(peek(forvalues)[1]):to_equal("BAZ")
			expect(peek(forvalues)[2]):to_equal("QUX")
			cleanup(scope)
		end)
		test("use constants", function()
			local scope = {}
			local data = { "foo", "bar" }
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				return value .. use("baz")
			end)

			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("foobaz")
			expect(peek(forvalues)[2]):to_equal("barbaz")
			cleanup(scope)
		end)
		test("use state", function()
			local scope = {}
			local data = { "foo", "bar" }
			local suffix = Value(scope, "first")
			local forvalues = ForValues(scope, data, function(use, _, value: string)
				return value .. use(suffix)
			end)
			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("foofirst")
			expect(peek(forvalues)[2]):to_equal("barfirst")
			suffix:set("second")
			expect(peek(forvalues)[1]):to_equal("foosecond")
			expect(peek(forvalues)[2]):to_equal("barsecond")
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
			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("foofirst")
			expect(peek(forvalues)[2]):to_equal("barfirst")
			expect(peek(forvalues)[3]):to_equal("bazfirst")
			suffix:set("second")
			expect(peek(forvalues))
				:to_never_have_value("foofirst")
				:to_never_have_value("barfirst")
				:to_never_have_value("bazfirst")
			expect(peek(forvalues)[1]):to_equal("foosecond")
			expect(peek(forvalues)[2]):to_equal("bazsecond")
			expect(peek(forvalues)[3]):to_never_exist()
			expect(destroyed.foofirst):to_equal(true)
			expect(destroyed.barfirst):to_equal(true)
			expect(destroyed.bazfirst):to_equal(true)
			expect(destroyed.foosecond):to_never_exist()
			expect(destroyed.barsecond):to_equal(true)
			expect(destroyed.foosecond):to_never_exist()
			suffix:set("third")
			expect(peek(forvalues))
				:to_never_have_value("foofirst")
				:to_never_have_value("barfirst")
				:to_never_have_value("bazfirst")
				:to_never_have_value("foosecond")
				:to_never_have_value("barsecond")
				:to_never_have_value("bazsecond")
			expect(peek(forvalues)[1]):to_equal("foothird")
			expect(peek(forvalues)[2]):to_equal("barthird")
			expect(peek(forvalues)[3]):to_equal("bazthird")

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
			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("foo")
			expect(peek(forvalues)[2]):to_equal("baz")
			expect(peek(forvalues)[3]):to_never_exist()
			omit_third:set(true)
			expect(peek(forvalues)[1]):to_equal("foo")
			expect(peek(forvalues)[2]):to_never_exist()
			expect(peek(forvalues)[3]):to_never_exist()
			omit_third:set(false)
			expect(peek(forvalues)[1]):to_equal("foo")
			expect(peek(forvalues)[2]):to_equal("baz")
			expect(peek(forvalues)[3]):to_never_exist()
			cleanup(scope)
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
			expect(peek(forvalues)):to_be_a("table")
			expect(peek(forvalues)[1]):to_equal("10")
			expect(peek(forvalues)[2]):to_equal("20")
			expect(peek(forvalues)[3]):to_equal("30")
			expect(peek(forvalues)[4]):to_equal("40")
			expect(peek(forvalues)[5]):to_equal("50")
			data:set({ "50", "40", "30", "20", "10" })
			expect(peek(forvalues)[1]):to_equal("50")
			expect(peek(forvalues)[2]):to_equal("40")
			expect(peek(forvalues)[3]):to_equal("30")
			expect(peek(forvalues)[4]):to_equal("20")
			expect(peek(forvalues)[5]):to_equal("10")
			data:set({ "50", "30", "10", "40" })
			expect(peek(forvalues)[1]):to_equal("50")
			expect(peek(forvalues)[2]):to_equal("30")
			expect(peek(forvalues)[3]):to_equal("10")
			expect(peek(forvalues)[4]):to_equal("40")
			expect(peek(forvalues)[5]):to_never_exist()
			omit:set({ "30" })
			expect(peek(forvalues)[1]):to_equal("50")
			expect(peek(forvalues)[2]):to_equal("10")
			expect(peek(forvalues)[3]):to_equal("40")
			expect(peek(forvalues)[4]):to_never_exist()
			expect(peek(forvalues)[5]):to_never_exist()
			data:set({ "10", "20", "30", "40", "50" })
			expect(peek(forvalues)[1]):to_equal("10")
			expect(peek(forvalues)[2]):to_equal("20")
			expect(peek(forvalues)[3]):to_equal("40")
			expect(peek(forvalues)[4]):to_equal("50")
			expect(peek(forvalues)[5]):to_never_exist()
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
			expect(destructed.foo):to_never_exist()
			expect(destructed.bar):to_never_exist()
			expect(destructed.baz):to_never_exist()
			data:set({ "baz" })
			peek(forvalues)
			expect(destructed.foo):to_equal(true)
			expect(destructed.bar):to_equal(true)
			expect(destructed.baz):to_never_exist()
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
			expect(destructed.foo):to_never_exist()
			expect(destructed.bar):to_never_exist()
			cleanup(scope)
			expect(destructed.foo):to_equal(true)
			expect(destructed.bar):to_equal(true)
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
			cleanup(forvalues)
		end)
	end)
end
