local Safe = require("@fusion/safe/Safe")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("Safe", function(test: butler.Test)
		test("success", function()
			local value = Safe({
				try = function()
					return 1
				end,
				fallback = function()
					return 0
				end,
			})

			expect(value):to_equal(1)
		end)
		test("fallback", function()
			local value = Safe({
				try = function()
					error("TEST ERROR", 0)
					return 1
				end,
				fallback = function()
					return 0
				end,
			})

			expect(value):to_equal(0)
		end)
		test("fallback error handling", function()
			local value = Safe({
				try = function()
					error("TEST ERROR", 0)
					return 1
				end,
				fallback = function(err: string)
					return err
				end,
			})

			expect(value):to_equal("TEST ERROR")
		end)
	end)
end
