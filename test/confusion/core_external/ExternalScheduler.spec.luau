local ExternalScheduler = require("@fusion/core_external/ExternalScheduler")
local external = require("@fusion/core_external/types")

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
		test("task functions throw with no set scheduler", function()
			ExternalScheduler.set_scheduler(nil)

			expect(ExternalScheduler.do_task_immediate):to_throw_with(external.missing_scheduler)
			expect(ExternalScheduler.do_task_delayed):to_throw_with(external.missing_scheduler)
			expect(ExternalScheduler.do_task_deferred):to_throw_with(external.missing_scheduler)
			expect(ExternalScheduler.cancel_task):to_throw_with(external.missing_scheduler)
		end)
		test("task functions call scheduler functions", function()
			local do_task_immediate_called = false
			local do_task_delayed_called = false
			local do_task_deferred_called = false
			local cancel_task_called = false

			ExternalScheduler.set_scheduler({
				start_scheduler = function() end,
				stop_scheduler = function() end,
				do_task_immediate = function()
					do_task_immediate_called = true
				end,
				do_task_delayed = function()
					do_task_delayed_called = true
				end,
				do_task_deferred = function()
					do_task_deferred_called = true
				end,
				cancel_task = function()
					cancel_task_called = true
				end,
			})

			expect(do_task_immediate_called):to_equal(false)
			expect(do_task_delayed_called):to_equal(false)
			expect(do_task_deferred_called):to_equal(false)
			expect(cancel_task_called):to_equal(false)

			ExternalScheduler.do_task_immediate()
			ExternalScheduler.do_task_delayed()
			ExternalScheduler.do_task_deferred()
			ExternalScheduler.cancel_task()

			expect(do_task_immediate_called):to_equal(true)
			expect(do_task_delayed_called):to_equal(true)
			expect(do_task_deferred_called):to_equal(true)
			expect(cancel_task_called):to_equal(true)

			ExternalScheduler.set_scheduler(nil)
		end)
		test("binding to and unbinding from update steps", function()
			local was_invoked = false
			local unbind = ExternalScheduler.bind_to_update_step(function(now: number)
				was_invoked = true
				expect(now):to_be_a("number")
			end)

			expect(was_invoked):to_equal(false)
			expect(unbind):to_be_a("function")

			ExternalScheduler.perform_update_step()

			expect(was_invoked):to_equal(true)

			was_invoked = false
			unbind()

			ExternalScheduler.perform_update_step()

			expect(was_invoked):to_equal(false)
		end)
		test("get_last_update", function()
			local last_update = os.clock()
			ExternalScheduler.perform_update_step()

			expect(ExternalScheduler.get_last_update()):to_be_near(last_update, 0.001)
		end)
		test("get_delta_time", function()
			local last_update = os.clock()
			ExternalScheduler.perform_update_step()

			local now = os.clock()
			ExternalScheduler.perform_update_step()

			expect(ExternalScheduler.get_delta_time()):to_be_near(now - last_update, 0.001)
		end)
	end)
end
