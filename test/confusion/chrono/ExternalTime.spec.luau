const ExternalScheduler = require("@fusion/core_external/ExternalScheduler")
const ExternalTime = require("@fusion/chrono/ExternalTime")
const SpecScheduler = require("../../SpecScheduler")
const cleanup = require("@fusion/core_memory/cleanup")
const observe = require("@fusion/core_graph/observe")
const peek = require("@fusion/core_state/peek")

const butler = require("@butler/butler")

return function(configured: butler.Configured)
	const expect = configured.expect

	return configured.unit("ExternalTime", function(test: butler.Test)
		test("constructs", function()
			ExternalScheduler.set_scheduler(SpecScheduler)
			const scope = {}
			const externaltime = ExternalTime(scope)
			expect(externaltime):to_be_a("table")
			expect(externaltime.type):to_equal("state")
			expect(externaltime.kind):to_equal("ExternalTime")
			expect(scope):to_have_value(externaltime.oldest_task)
			cleanup(scope)
			ExternalScheduler.set_scheduler(nil)
		end)
		test("updates", function()
			ExternalScheduler.set_scheduler(SpecScheduler)
			const scope = {}
			const externaltime = ExternalTime(scope)

			expect(peek(externaltime)):to_be_less_than(externaltime.created_at)

			const prestepped_a = os.clock()
			SpecScheduler.step()
			expect(peek(externaltime)):to_be_greater_than(prestepped_a)

			const prestepped_b = os.clock()
			SpecScheduler.step()
			expect(peek(externaltime)):to_be_greater_than(prestepped_b)

			cleanup(scope)
			ExternalScheduler.set_scheduler(nil)
		end)
		test("disabling", function()
			ExternalScheduler.set_scheduler(SpecScheduler)
			const scope = {}
			const externaltime = ExternalTime(scope)

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
			ExternalScheduler.set_scheduler(nil)
		end)
	end)
end
