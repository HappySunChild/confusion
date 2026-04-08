local SpecScheduler = require("../../SpecScheduler")
local Timer = require("@fusion/chrono/Timer")
local cleanup = require("@fusion/core_memory/cleanup")
local observe = require("@fusion/core_graph/observe")
local peek = require("@fusion/core_use/peek")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("Timer", function(test: butler.Test)
		test("constructs", function()
			local scope = {}
			local externaltime = Timer(scope)
			expect(externaltime):to_be_a("table")
			expect(externaltime.type):to_equal("state")
			expect(externaltime.kind):to_equal("Timer")
			expect(scope):to_have_value(externaltime._oldest_task)
			cleanup(scope)
		end)
		test("updates", function()
			local scope = {}
			local timer = Timer(scope)

			SpecScheduler.step()
			local last_value = peek(timer)
			expect(last_value):to_be_greater_than(0)

			SpecScheduler.step()
			expect(peek(timer)):to_be_greater_than(last_value)

			cleanup(scope)
		end)
		test("pausing", function()
			local scope = {}
			local timer = Timer(scope)

			local changes = 0
			local last_value = 0

			observe(scope, timer, function()
				changes += 1
			end)

			expect(changes):to_equal(0)
			expect(last_value):to_equal(0)

			SpecScheduler.step()
			expect(changes):to_equal(1)
			expect(peek(timer)):to_never_equal(last_value)
			last_value = peek(timer)

			timer:pause()
			expect(changes):to_equal(1)
			expect(peek(timer)):to_equal(last_value)

			SpecScheduler.step()
			expect(peek(timer)):to_equal(last_value)

			timer:unpause()
			expect(changes):to_equal(1)
			expect(peek(timer)):to_equal(last_value)

			SpecScheduler.step()
			expect(changes):to_equal(2)
			expect(peek(timer)):to_be_greater_than(last_value)

			cleanup(scope)
		end)
		test("zero", function()
			local scope = {}
			local timer = Timer(scope)

			expect(peek(timer)):to_equal(0)

			SpecScheduler.step()
			expect(peek(timer)):to_be_greater_than(0)

			timer:zero()
			expect(peek(timer)):to_equal(0)

			SpecScheduler.step()
			expect(peek(timer)):to_be_greater_than(0)

			cleanup(scope)
		end)
	end)
end
