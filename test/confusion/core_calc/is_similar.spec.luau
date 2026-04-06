local is_similar = require("@fusion/core_calc/is_similar")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	local function run_eq_test(constructor: (...any) -> any, ...: any)
		local output

		local original, same_eq, diff_eq = constructor(...), constructor(...), constructor(...)
		local original_mt = getmetatable(original)
		local same_eq_mt = getmetatable(same_eq)
		local diff_eq_mt = getmetatable(diff_eq)
		original_mt.__eq = function()
			return output
		end
		same_eq_mt.__eq = original_mt.__eq
		diff_eq_mt.__eq = function()
			return output
		end
		original_mt.__metatable = "This metatable is locked"
		same_eq_mt.__metatable = "This metatable is locked"
		diff_eq_mt.__metatable = "This metatable is locked"

		expect(is_similar(original, diff_eq)):to_equal(false)
		expect(is_similar(same_eq, diff_eq)):to_equal(false)
		output = true
		expect(is_similar(original, original)):to_equal(output)
		expect(is_similar(original, same_eq)):to_equal(output)
		expect(is_similar(same_eq, diff_eq)):to_equal(false)
		output = false
		expect(is_similar(original, original)):to_equal(output)
		expect(is_similar(original, same_eq)):to_equal(output)
		expect(is_similar(same_eq, diff_eq)):to_equal(false)
	end

	return unit("is_similar", function(test: butler.Test)
		test("identical", function()
			expect(is_similar(123, 123)):to_equal(true)
		end)
		test("different", function()
			expect(is_similar(123, 321)):to_equal(false)
		end)
		test("nan", function()
			expect(is_similar(0 / 0, math.huge / math.huge)):to_equal(true)
		end)
		test("mutable table", function()
			local self = { foo = "bar" }
			expect(is_similar(self, self)):to_equal(false)
		end)
		test("frozen table", function()
			local self = table.freeze({ foo = "bar" })
			local other = table.freeze({ foo = "bar" })
			expect(is_similar(self, self)):to_equal(true)
			expect(is_similar(self, other)):to_equal(false)
		end)
		test("userdata no metatable", function()
			local self = newproxy(false)
			local other = newproxy(false)
			expect(is_similar(self, self)):to_equal(true)
			expect(is_similar(self, other)):to_equal(false)
		end)
		test("userdata default metatable", function()
			local self = newproxy(true)
			local other = newproxy(true)
			expect(is_similar(self, self)):to_equal(true)
			expect(is_similar(self, other)):to_equal(false)
		end)
		test("__eq userdata", function()
			run_eq_test(newproxy, true)
		end)
		test("__eq mutable table", function()
			run_eq_test(function()
				return setmetatable({}, {})
			end)
		end)
		test("__eq frozen tables", function()
			run_eq_test(function()
				return table.freeze(setmetatable({}, {}))
			end)
		end)
	end)
end
