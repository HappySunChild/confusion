local Chain = require("@fusion/chain/Chain")
local cleanup = require("@fusion/core_memory/cleanup")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("Chain", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local pipe = Chain(scope, nil)

			expect(pipe):to_be_a("table")
			expect(pipe.type):to_equal("Chain")

			cleanup(scope)
		end)
		test("resolves", function()
			local scope = {}
			local pipe = Chain(scope, "foo")

			expect(pipe.latent):to_equal("foo")

			cleanup(scope)
		end)
		test("modify", function()
			local scope = {}
			local pipe = Chain(scope, 0)

			local function incr(_, current: number)
				return current + 1
			end

			expect(pipe.latent):to_equal(0)

			pipe:modify(incr)
			expect(pipe.latent):to_equal(1)

			pipe:modify(incr)
			expect(pipe.latent):to_equal(2)

			cleanup(scope)
		end)
		test("scope", function()
			local scope = {}
			local pipe = Chain(scope, 0)

			local external_count = 0

			local function func(scope: { any }, current: any)
				table.insert(scope, function()
					external_count += 1
				end)

				return current
			end

			pipe:modify(func):modify(func)

			cleanup(scope)

			expect(external_count):to_equal(2)
		end)
	end)
end
