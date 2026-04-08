local butler = require("@butler/butler")

local cleanup = require("@fusion/core_memory/cleanup")

return function(configured: butler.Configured)
	local unit, expect = configured.unit, configured.expect

	return unit("cleanup", function(test: butler.Test)
		test("callback", function()
			local ran = false

			cleanup(function()
				ran = true
			end)

			expect(ran):to_equal(true)
		end)

		for _, method in { "destroy", "Destroy", "disconnect", "Disconnect" } do
			test(`calls {method}`, function(remark: (string) -> ())
				local ran = false

				cleanup({
					[method] = function()
						ran = true
					end,
				})

				expect(ran):to_equal(true)
			end)
		end

		test("scope", function()
			local runs = {}
			local scope = {}
			scope[3] = function()
				table.insert(runs, 3)
			end
			scope[1] = function()
				table.insert(runs, 1)
			end
			scope[2] = function()
				table.insert(runs, 2)
			end
			cleanup(scope)
			expect(runs[1]):to_equal(3)
			expect(runs[2]):to_equal(2)
			expect(runs[3]):to_equal(1)
		end)
		test("recursion", function()
			local function foo()
				cleanup(foo)
			end
			expect(foo):to_throw()
		end)
	end)
end
