local lerp_type = require("@fusion/lerp/lerp_type")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("lerp_type", function(test: butler.Test)
		test("numbers", function()
			local a = 0
			local b = 1

			expect(lerp_type(a, b, 0)):to_equal(0)
			expect(lerp_type(a, b, 0.5)):to_equal(0.5)
			expect(lerp_type(a, b, 1)):to_equal(1)
			expect(lerp_type(a, b, -1)):to_equal(-1)
			expect(lerp_type(a, b, 2)):to_equal(2)
		end)
		test("vectors", function()
			local a = vector.zero
			local b = vector.one

			expect(lerp_type(a, b, 0)):to_equal(vector.zero)
			expect(lerp_type(a, b, 0.5)):to_equal(vector.one * 0.5)
			expect(lerp_type(a, b, 1)):to_equal(vector.one)
			expect(lerp_type(a, b, -1)):to_equal(-vector.one)
			expect(lerp_type(a, b, 2)):to_equal(vector.one * 2)
		end)
		test("mixed", function()
			local a = 0
			local b = "hello"

			expect(lerp_type(a, b, 0)):to_equal(a)
			expect(lerp_type(a, b, 1)):to_equal(b)
			expect(lerp_type(a, b, 0.2)):to_equal(a)
			expect(lerp_type(a, b, 0.5)):to_equal(b)
			expect(lerp_type(a, b, 0.8)):to_equal(b)
		end)
	end)
end
