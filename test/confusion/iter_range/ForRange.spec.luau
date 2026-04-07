local ForRange = require("@fusion/iter_range/ForRange")
local Value = require("@fusion/core_state/Value")
local cleanup = require("@fusion/core_memory/cleanup")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ForRange", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local forrange = ForRange(scope, 0, 1, function() end)
			expect(forrange):to_have_pairs({ type = "state", kind = "Iter" })
			expect(scope):to_have_value(forrange._oldest_task)
			cleanup(forrange)
		end)
		test("iterates, constants", function()
			local scope = {}
			local start = 1
			local finish = 3
			local forrange = ForRange(scope, start, finish, function(_, _, value: number)
				return -value
			end)
			expect(peek(forrange)):to_have_pairs({ -1, -2, -3 })
			cleanup(scope)
		end)
		test("iterates, state", function()
			local scope = {}
			local start = Value(scope, 1)
			local finish = Value(scope, 3)
			local forrange = ForRange(scope, start, finish, function(_, _, value: number)
				return -value
			end)
			expect(peek(forrange)):to_have_pairs({ -1, -2, -3 })
			finish:set(6)
			expect(peek(forrange)):to_have_pairs({ -1, -2, -3, -4, -5, -6 })
			start:set(4)
			expect(peek(forrange)):to_have_pairs({ -4, -5, -6 })
			cleanup(forrange)
		end)
		test("iterates, constant step", function()
			local scope = {}
			local forrange = ForRange(scope, 1, 8, function(_, _, value: number)
				return value
			end, 2)
			expect(peek(forrange)):to_have_pairs({ 1, 3, 5, 7 })
			cleanup(scope)
		end)
		test("iterates, state step", function()
			local scope = {}
			local step = Value(scope, 0.5)
			local forrange = ForRange(scope, 1, 3, function(_, _, value: number)
				return value
			end, step)
			expect(peek(forrange)):to_have_pairs({ 1, 1.5, 2, 2.5, 3 })
			step:set(1)
			expect(peek(forrange)):to_have_pairs({ 1, 2, 3 })
			step:set(2)
			expect(peek(forrange)):to_have_pairs({ 1, 3 })
			cleanup(scope)
		end)
		test("use, constants", function()
			local scope = {}
			local forrange = ForRange(scope, 1, 3, function(use, _, value: number)
				return value + use(1)
			end)
			expect(peek(forrange)):to_have_pairs({ 2, 3 })
			cleanup(scope)
		end)
		test("use, state", function()
			local scope = {}
			local offset = Value(scope, 1)
			local forrange = ForRange(scope, 1, 3, function(use, _, value: string)
				return value + use(offset)
			end)
			expect(peek(forrange)):to_have_pairs({ 2, 3 })
			offset:set(-1)
			expect(peek(forrange)):to_have_pairs({ 0, 1 })
			cleanup(scope)
		end)
		test("errors", function()
			local scope = {}
			local offset = Value(scope, 1)
			local destroyed = {}
			local forrange = ForRange(scope, 1, 3, function(use, inner_scope, value: number)
				local generated = value + use(offset)
				table.insert(inner_scope, function()
					destroyed[generated] = true
				end)
				if value == 2 and use(offset) == -2 then
					error("This is an intentional error from a unit test")
				end
				return generated
			end)
			expect(peek(forrange)):to_have_pairs({ 2, 3, 4 })
			offset:set(-2)
			expect(peek(forrange)):to_have_pairs({ -1, nil, 1 })
			expect(destroyed):to_have_keys({ 0, 2, 3, 4 })
			offset:set(3)
			expect(peek(forrange)):to_have_pairs({ 4, 5, 6 })
			expect(destroyed):to_have_keys({ -1, 1 })
			cleanup(scope)
		end)
		test("nil", function()
			local scope = {}
			local omit_third = Value(scope, false)
			local forrange = ForRange(scope, 1, 3, function(use, _, value: number)
				if value == 2 then
					return nil
				end
				if use(omit_third) and value == 3 then
					return nil
				end
				return value
			end)
			expect(peek(forrange)):to_have_pairs({ 1, nil, 3 })
			omit_third:set(true)
			expect(peek(forrange)):to_have_pairs({ 1, nil, nil })
			omit_third:set(false)
			expect(peek(forrange)):to_have_pairs({ 1, nil, 3 })
			cleanup(scope)
		end)
		test("cleanup, state change", function()
			local scope = {}
			local destructed = {}
			local start = Value(scope, 1)
			local finish = Value(scope, 3)
			local forrange = ForRange(scope, start, finish, function(_, inner_scope, value: number)
				table.insert(inner_scope, function()
					destructed[value] = true
				end)
				return value
			end)
			peek(forrange)
			expect(destructed):to_be_empty()
			finish:set(1)
			peek(forrange)
			expect(destructed):to_have_keys({ 2, 3 })
			cleanup(scope)
		end)
		test("cleanup, external cleanup", function()
			local scope = {}
			local destructed = {}
			local forrange = ForRange(scope, 1, 3, function(_, inner_scope, value: number)
				table.insert(inner_scope, function()
					destructed[value] = true
				end)
				return value
			end)
			peek(forrange)
			expect(destructed):to_never_have_keys({ 1, 2, 3 })
			cleanup(scope)
			expect(destructed):to_have_keys({ 1, 2, 3 })
		end)
	end)
end
