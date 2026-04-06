local ExternalTime = require("@fusion/chrono/ExternalTime")
local SpecScheduler = require("../../SpecScheduler")
local cleanup = require("@fusion/core_memory/cleanup")
local observe = require("@fusion/core_graph/observe")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ExternalTime", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local externaltime = ExternalTime(scope)
			expect(externaltime):to_be_a("table")
			expect(externaltime.type):to_equal("state")
			expect(externaltime.kind):to_equal("ExternalTime")
			expect(scope):to_have_value(externaltime._oldest_task)
			cleanup(scope)
		end)
		test("updates", function()
			local scope = {}
			local externaltime = ExternalTime(scope)

			expect(peek(externaltime)):to_be_less_than(externaltime.created_at)

			local prestepped_a = os.clock()
			SpecScheduler.step()
			expect(peek(externaltime)):to_be_greater_than(prestepped_a)

			local prestepped_b = os.clock()
			SpecScheduler.step()
			expect(peek(externaltime)):to_be_greater_than(prestepped_b)

			cleanup(scope)
		end)
		test("disabling", function()
			local scope = {}
			local externaltime = ExternalTime(scope)

			local changes = 0

			observe(scope, externaltime, function()
				changes += 1
			end)

			expect(externaltime:is_enabled()):to_equal(true)
			expect(changes):to_equal(0)
			SpecScheduler.step()
			expect(changes):to_equal(1)
			externaltime:disable()
			expect(externaltime:is_enabled()):to_equal(false)
			SpecScheduler.step()
			expect(changes):to_equal(1)
			externaltime:enable()
			expect(externaltime:is_enabled()):to_equal(true)
			SpecScheduler.step()
			expect(changes):to_equal(2)
			cleanup(scope)
		end)
	end)
end
