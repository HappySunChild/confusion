local butler = require("@butler/butler")

local insert = require("@fusion/core_memory/insert")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("insert", function(test: butler.Test)
		test("nothing", function()
			local list: any = { 1, 2, 3 }
			insert(list)
			expect(list[3]):to_equal(3)
			expect(list[4]):to_never_exist()
		end)
		test("single", function()
			local list: any = { 1, 2, 3 }
			local a = insert(list, 4)
			expect(a):to_equal(4)
			expect(list[3]):to_equal(3)
			expect(list[4]):to_equal(4)
			expect(list[5]):to_never_exist()
		end)
		test("bulk", function()
			local list: any = { 1, 2, 3 }
			local a, b, c = insert(list, 4, 5, 6)
			expect(a):to_equal(4)
			expect(b):to_equal(5)
			expect(c):to_equal(6)
			expect(list[3]):to_equal(3)
			expect(list[4]):to_equal(4)
			expect(list[5]):to_equal(5)
			expect(list[6]):to_equal(6)
			expect(list[7]):to_never_exist()
		end)
	end)
end
