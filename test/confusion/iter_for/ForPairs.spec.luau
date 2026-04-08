local ForPairs = require("@fusion/iter_for/ForPairs")
local Value = require("@fusion/core_state/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForPairs", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forpairs = ForPairs(scope, {}, function() end)
			expect(forpairs):to_have_pairs({ type = "state", kind = "Iter" })
			expect(scope):to_have_value(forpairs._oldest_task)
			cleanup(scope)
		end)
		test("iterates, constants", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local forpairs = ForPairs(scope, data, function(_, _, key, value)
				return value, key
			end)
			expect(peek(forpairs))
				:to_never_have_keys({ "foo", "baz" })
				:to_have_pairs({ bar = "foo", qux = "baz" })
			cleanup(scope)
		end)
		test("iterates, state", function()
			local scope = {}
			local data = Value(scope, { foo = "bar", baz = "qux" })
			local forpairs = ForPairs(scope, data, function(_, _, key, value)
				return value, key
			end)
			expect(peek(forpairs))
				:to_never_have_keys({ "foo", "baz" })
				:to_have_pairs({ bar = "foo", qux = "baz" })
			data:set({ zab = "xuq", bar = "oof" })
			expect(peek(forpairs))
				:to_never_have_keys({ "bar", "qux" })
				:to_have_pairs({ xuq = "zab", oof = "bar" })
			cleanup(scope)
		end)
		test("use, constants", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local forpairs = ForPairs(scope, data, function(use, _, key: string, value: string)
				return value .. use("baz"), key .. use("baz")
			end)
			expect(peek(forpairs)):to_have_pairs({ barbaz = "foobaz", quxbaz = "bazbaz" })
			cleanup(scope)
		end)
		test("use, state", function()
			local scope = {}
			local data = { foo = "bar", baz = "qux" }
			local suffix = Value(scope, "first")
			local forpairs = ForPairs(scope, data, function(use, _, key: string, value: string)
				return value .. use(suffix), key .. use(suffix)
			end)
			expect(peek(forpairs)):to_have_pairs({ barfirst = "foofirst", quxfirst = "bazfirst" })
			suffix:set("second")
			expect(peek(forpairs))
				:to_never_have_keys({ "bazfirst", "quxfirst" })
				:to_have_pairs({ barsecond = "foosecond", quxsecond = "bazsecond" })
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
			expect(peek(forpairs)):to_have_pairs({
				ooffirst = "foofirst",
				rabfirst = "barfirst",
				zabfirst = "bazfirst",
			})
			suffix:set("second")
			expect(peek(forpairs))
				:to_never_have_keys({ "ooffirst", "rabfirst", "zabfirst", "rabsecond" })
				:to_have_pairs({ oofsecond = "foosecond", zabsecond = "bazsecond" })
			expect(destroyed)
				:to_never_have_keys({ "oofsecond", "zabsecond" })
				:to_have_keys({ "ooffirst", "rabfirst", "zabfirst", "rabsecond" })
			suffix:set("third")
			expect(peek(forpairs))
				:to_never_have_keys({
					"ooffirst",
					"rabfirst",
					"zabfirst",
					"oofsecond",
					"rabsecond",
					"zabsecond",
				})
				:to_have_pairs({
					oofthird = "foothird",
					rabthird = "barthird",
					zabthird = "bazthird",
				})
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
			expect(peek(forpairs))
				:to_never_have_keys({ "rab" })
				:to_have_pairs({ oof = "foo", zab = "baz" })
			omit_third:set(true)
			expect(peek(forpairs))
				:to_never_have_keys({ "rab", "zab" })
				:to_have_pairs({ oof = "foo" })
			omit_third:set(false)
			expect(peek(forpairs))
				:to_never_have_keys({ "rab" })
				:to_have_pairs({ oof = "foo", zab = "baz" })
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
			expect(destructed):to_never_have_keys({ "foo", "bar" })
			data:set({ baz = "zab" })
			peek(forpairs)
			expect(destructed):to_never_have_keys({ "baz" }):to_have_keys({ "foo", "bar" })
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
			expect(destructed):to_never_have_keys({ "foo", "bar" })
			cleanup(scope)
			expect(destructed):to_have_keys({ "foo", "bar" })
		end)
	end)
end
