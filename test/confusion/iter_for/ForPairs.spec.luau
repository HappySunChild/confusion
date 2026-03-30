local ForPairs = require("@fusion/iter_for/ForPairs")
local Value = require("@fusion/core_calc/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForPairs", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forpairs = ForPairs(scope, {}, function() end)

			expect(forpairs):to_be_a("table")
			expect(forpairs.type):to_equal("state")
			expect(forpairs.kind):to_equal("Iter")
			expect(scope):to_have_value(forpairs._oldest_task)

			cleanup(scope)
		end)
		test("iterates constants", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local forpairs = ForPairs(scope, data, function(_, _, key, value)
				return value, key
			end)

			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).foo):to_never_exist()
			expect(peek(forpairs).baz):to_never_exist()
			expect(peek(forpairs).bar):to_equal("foo")
			expect(peek(forpairs).qux):to_equal("baz")
			cleanup(scope)
		end)
		test("iterates state", function()
			local scope = {}
			local data = Value(scope, { foo = "bar", baz = "qux" })
			local forpairs = ForPairs(scope, data, function(_, _, key, value)
				return value, key
			end)
			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).foo):to_never_exist()
			expect(peek(forpairs).baz):to_never_exist()
			expect(peek(forpairs).bar):to_equal("foo")
			expect(peek(forpairs).qux):to_equal("baz")
			data:set({ zab = "xuq", bar = "oof" })
			expect(peek(forpairs).bar):to_never_exist()
			expect(peek(forpairs).qux):to_never_exist()
			expect(peek(forpairs).xuq):to_equal("zab")
			expect(peek(forpairs).oof):to_equal("bar")
			cleanup(scope)
		end)
		test("use constants", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local forpairs = ForPairs(scope, data, function(use, _, key: string, value: string)
				return value .. use("baz"), key .. use("baz")
			end)
			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).barbaz):to_equal("foobaz")
			expect(peek(forpairs).quxbaz):to_equal("bazbaz")
			cleanup(scope)
		end)
		test("use state", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local suffix = Value(scope, "first")
			local forpairs = ForPairs(scope, data, function(use, _, key: string, value: string)
				return value .. use(suffix), key .. use(suffix)
			end)
			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).barfirst):to_equal("foofirst")
			expect(peek(forpairs).quxfirst):to_equal("bazfirst")
			suffix:set("second")
			expect(peek(forpairs).barfirst):to_never_exist()
			expect(peek(forpairs).quxfirst):to_never_exist()
			expect(peek(forpairs).barsecond):to_equal("foosecond")
			expect(peek(forpairs).quxsecond):to_equal("bazsecond")
			cleanup(scope)
		end)
		test("errors", function()
			local scope = {}
			local data = { foo = "oof", bar = "rab", baz = "zab" }
			local suffix = Value(scope, "first")
			local destroyed = {}
			local forpairs = ForPairs(
				scope,
				data,
				function(use, inner_scope, key: string, value: string)
					local generated_key = value .. use(suffix)
					local generated_value = key .. use(suffix)
					table.insert(inner_scope, function()
						destroyed[generated_key] = true
					end)
					if key == "bar" and use(suffix) == "second" then
						error("This is an intentional error from a unit test")
					end
					return generated_key, generated_value
				end
			)
			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).ooffirst):to_equal("foofirst")
			expect(peek(forpairs).rabfirst):to_equal("barfirst")
			expect(peek(forpairs).zabfirst):to_equal("bazfirst")
			suffix:set("second")
			expect(peek(forpairs).ooffirst):to_never_exist()
			expect(peek(forpairs).rabfirst):to_never_exist()
			expect(peek(forpairs).zabfirst):to_never_exist()
			expect(peek(forpairs).oofsecond):to_equal("foosecond")
			expect(peek(forpairs).rabsecond):to_never_exist()
			expect(peek(forpairs).zabsecond):to_equal("bazsecond")
			expect(destroyed.ooffirst):to_equal(true)
			expect(destroyed.rabfirst):to_equal(true)
			expect(destroyed.zabfirst):to_equal(true)
			expect(destroyed.oofsecond):to_never_exist()
			expect(destroyed.rabsecond):to_equal(true)
			expect(destroyed.zabsecond):to_never_exist()
			suffix:set("third")
			expect(peek(forpairs).ooffirst):to_never_exist()
			expect(peek(forpairs).rabfirst):to_never_exist()
			expect(peek(forpairs).zabfirst):to_never_exist()
			expect(peek(forpairs).oofsecond):to_never_exist()
			expect(peek(forpairs).rabsecond):to_never_exist()
			expect(peek(forpairs).zabsecond):to_never_exist()
			expect(peek(forpairs).oofthird):to_equal("foothird")
			expect(peek(forpairs).rabthird):to_equal("barthird")
			expect(peek(forpairs).zabthird):to_equal("bazthird")
			cleanup(scope)
		end)
		test("nil", function()
			local scope = {}
			local data = { foo = "oof", bar = "rab", baz = "zab" }
			local omit_third = Value(scope, false)
			local forpairs = ForPairs(scope, data, function(use, _, key: string, value: string)
				if key == "bar" then
					return nil, nil
				end
				if use(omit_third) and key == "baz" then
					return value, nil
				end
				return value, key
			end)
			expect(peek(forpairs)):to_be_a("table")
			expect(peek(forpairs).oof):to_equal("foo")
			expect(peek(forpairs).rab):to_never_exist()
			expect(peek(forpairs).zab):to_equal("baz")
			omit_third:set(true)
			expect(peek(forpairs).oof):to_equal("foo")
			expect(peek(forpairs).rab):to_never_exist()
			expect(peek(forpairs).zab):to_never_exist()
			omit_third:set(false)
			expect(peek(forpairs).oof):to_equal("foo")
			expect(peek(forpairs).rab):to_never_exist()
			expect(peek(forpairs).zab):to_equal("baz")
			cleanup(scope)
		end)
		test("cleanup, state change", function()
			local scope = {}
			local destructed = {}
			local data = Value(scope, { foo = "oof", bar = "rab" })
			local forpairs = ForPairs(
				scope,
				data,
				function(_, inner_scope, key: string, value: string)
					table.insert(inner_scope, function()
						destructed[key] = true
					end)
					return value, key
				end
			)
			peek(forpairs)
			expect(destructed.foo):to_never_exist()
			expect(destructed.bar):to_never_exist()
			data:set({ baz = "zab" })
			peek(forpairs)
			expect(destructed.foo):to_equal(true)
			expect(destructed.bar):to_equal(true)
			expect(destructed.baz):to_never_exist()
			cleanup(scope)
		end)
		test("cleanup, external cleanup", function()
			local scope = {}
			local destructed = {}
			local data = Value(scope, { foo = "oof", bar = "rab" })
			local forpairs = ForPairs(
				scope,
				data,
				function(_, inner_scope, key: string, value: string)
					table.insert(inner_scope, function()
						destructed[key] = true
					end)
					return value, key
				end
			)
			peek(forpairs)
			expect(destructed.foo):to_never_exist()
			expect(destructed.bar):to_never_exist()
			cleanup(scope)
			expect(destructed.foo):to_equal(true)
			expect(destructed.bar):to_equal(true)
		end)
	end)
end
