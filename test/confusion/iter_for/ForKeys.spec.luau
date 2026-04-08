local ForKeys = require("@fusion/iter_for/ForKeys")
local Value = require("@fusion/core_state/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForKeys", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forkeys = ForKeys(scope, {}, function() end)
			expect(forkeys):to_have_pairs({ type = "state", kind = "Iter" })
			expect(scope):to_have_value(forkeys._oldest_task)
			cleanup(scope)
		end)
		test("iterates, constants", function()
			local scope = {}
			local data = { foo = 1, bar = 2 }
			local forkeys = ForKeys(scope, data, function(_, _, key: string)
				return string.upper(key)
			end)
			expect(peek(forkeys)):to_have_pairs({ FOO = 1, BAR = 2 })
			cleanup(scope)
		end)
		test("iterates, state", function()
			local scope = {}
			local data = Value(scope, { foo = 1, bar = 2 })
			local forkeys = ForKeys(scope, data, function(_, _, key: string)
				return string.upper(key)
			end)
			expect(peek(forkeys)):to_have_pairs({ FOO = 1, BAR = 2 })
			data:set({ baz = 3, qux = 4 })
			expect(peek(forkeys))
				:to_never_have_keys({ "FOO", "BAR" })
				:to_have_pairs({ BAZ = 3, QUX = 4 })
			cleanup(scope)
		end)
		test("use, constants", function()
			local scope = {}
			local data = { foo = 1, bar = 2 }
			local forkeys = ForKeys(scope, data, function(use, _, key: string)
				return key .. use("baz")
			end)
			expect(peek(forkeys)):to_have_pairs({ foobaz = 1, barbaz = 2 })
			cleanup(scope)
		end)
		test("use, state", function()
			local scope = {}
			local data = { foo = 1, bar = 2 }
			local suffix = Value(scope, "first")
			local forkeys = ForKeys(scope, data, function(use, _, key: string)
				return key .. use(suffix)
			end)
			expect(peek(forkeys)):to_have_pairs({ foofirst = 1, barfirst = 2 })
			suffix:set("second")
			expect(peek(forkeys))
				:to_never_have_keys({ "foofirst", "barfirst" })
				:to_have_pairs({ foosecond = 1, barsecond = 2 })
			cleanup(scope)
		end)
		test("errors", function()
			local scope = {}
			local data = { foo = 1, bar = 2, baz = 3 }
			local suffix = Value(scope, "first")
			local destroyed = {}
			local forkeys = ForKeys(scope, data, function(use, inner_scope, key: string)
				local generated = key .. use(suffix)
				table.insert(inner_scope, function()
					destroyed[generated] = true
				end)
				if key == "bar" and use(suffix) == "second" then
					error("This is an intentional error from a unit test")
				end
				return generated
			end)
			expect(peek(forkeys)):to_have_pairs({ foofirst = 1, barfirst = 2, bazfirst = 3 })
			suffix:set("second")
			expect(peek(forkeys))
				:to_never_have_keys({ "foofirst", "barfirst", "bazfirst", "barsecond" })
				:to_have_pairs({ foosecond = 1, bazsecond = 3 })
			expect(destroyed)
				:to_have_keys({ "foofirst", "barfirst", "bazfirst", "barsecond" })
				:to_never_have_keys({ "foosecond", "bazsecond" })
			suffix:set("third")
			expect(peek(forkeys))
				:to_never_have_keys({
					"foofirst",
					"barfirst",
					"bazfirst",
					"foosecond",
					"barsecond",
					"bazsecond",
				})
				:to_have_pairs({ foothird = 1, barthird = 2, bazthird = 3 })
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
			local data = { foo = 1, bar = 2, baz = 3 }
			local omit_third = Value(scope, false)
			local forkeys = ForKeys(scope, data, function(use, _, key: string)
				if key == "bar" then
					return nil
				end
				if use(omit_third) and key == "baz" then
					return nil
				end
				return key
			end)
			expect(peek(forkeys)):to_have_pairs({ foo = 1, baz = 3 }):to_never_have_keys({ "bar" })
			omit_third:set(true)
			expect(peek(forkeys)):to_have_pairs({ foo = 1 }):to_never_have_keys({ "bar", "baz" })
			omit_third:set(false)
			expect(peek(forkeys)):to_have_pairs({ foo = 1, baz = 3 }):to_never_have_keys({ "bar" })
			cleanup(scope)
		end)
		test("cleanup, state change", function()
			local scope = {}
			local destructed = {}
			local data = Value(scope, { foo = 1, bar = 2 })
			local forkeys = ForKeys(scope, data, function(_, inner_scope, key: string)
				table.insert(inner_scope, function()
					destructed[key] = true
				end)
				return key
			end)
			peek(forkeys)
			expect(destructed):to_never_have_keys({ "foo", "bar", "baz" })
			data:set({ baz = 3 })
			peek(forkeys)
			expect(destructed):to_have_keys({ "foo", "bar" }):to_never_have_key("baz")
			cleanup(scope)
		end)
		test("cleanup, external cleanup", function()
			local scope = {}
			local destructed = {}
			local data = { foo = 1, bar = 2 }
			local forkeys = ForKeys(scope, data, function(_, inner_scope, key: string)
				table.insert(inner_scope, function()
					destructed[key] = true
				end)
				return key
			end)
			peek(forkeys)
			expect(destructed):to_never_have_keys({ "foo", "bar" })
			cleanup(scope)
			expect(destructed):to_have_keys({ "foo", "bar" })
		end)
		test("roaming keys", function()
			local scope = {}
			local data = Value(scope, { foo = 1, bar = 2 })
			local computations = 0
			local forkeys = ForKeys(scope, data, function(_, _, key: string)
				computations += 1
				return string.upper(key)
			end)
			peek(forkeys)
			expect(computations):to_equal(2)
			data:set({ foo = 3, bar = 4 })
			peek(forkeys)
			expect(computations):to_equal(2)
			data:set({ foo = 3, bar = 4, baz = 5 })
			peek(forkeys)
			expect(computations):to_equal(3)
			data:set({ qux = 6 })
			peek(forkeys)
			expect(computations):to_equal(4)
			cleanup(scope)
		end)
	end)
end
