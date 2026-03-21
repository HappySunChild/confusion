local ExternalScheduler = require("@fusion/core_external/ExternalScheduler")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ExternalScheduler", function(test: butler.Test)
		test("scheduler starts and stops", function()
			local scheduler_a_active = false
			local scheduler_b_active = false

			local scheduler_a = {
				start_scheduler = function()
					scheduler_a_active = true
				end,
				stop_scheduler = function()
					scheduler_a_active = false
				end,
			}
			local scheduler_b = {
				start_scheduler = function()
					scheduler_b_active = true
				end,
				stop_scheduler = function()
					scheduler_b_active = false
				end,
			}

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(false)

			ExternalScheduler.set_scheduler(scheduler_a)

			expect(scheduler_a_active):to_equal(true)
			expect(scheduler_b_active):to_equal(false)

			ExternalScheduler.set_scheduler(scheduler_b)

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(true)

			ExternalScheduler.set_scheduler(nil)

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(false)
		end)
		test("requires set scheduler", function()
			ExternalScheduler.set_scheduler(nil)

			expect(ExternalScheduler.do_task_immediate):to_throw()
			expect(ExternalScheduler.do_task_delayed):to_throw()
			expect(ExternalScheduler.do_task_deferred):to_throw()
		end)
		test("update steps", function()
			local was_invoked = false
			local disconnect = ExternalScheduler.bind_to_update_step(function(now: number)
				was_invoked = true
				expect(now):to_be_a("number")
			end)

			expect(was_invoked):to_equal(false)
			expect(disconnect):to_be_a("function")

			ExternalScheduler.perform_update_step()

			expect(was_invoked):to_equal(true)

			was_invoked = false
			disconnect()

			ExternalScheduler.perform_update_step()

			expect(was_invoked):to_equal(false)
		end)
	end)
end
