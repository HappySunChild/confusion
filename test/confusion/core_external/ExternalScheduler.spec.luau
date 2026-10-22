local ExternalScheduler = require("@fusion/core_external/ExternalScheduler")
local external = require("@fusion/core_external/types")

local butler = require("@butler/butler")

return function(configured: butler.Configured)
	local expect = configured.expect

	return configured.unit("ExternalScheduler", function(test: butler.Test)
		test("scheduler starts and stops", function()
			local scheduler_a_active = false
			local scheduler_b_active = false

			local scheduler_a: external.ExternalScheduler = {
				start_scheduler = function()
					scheduler_a_active = true
				end,
				stop_scheduler = function()
					scheduler_a_active = false
				end,
			}
			local scheduler_b: external.ExternalScheduler = {
				start_scheduler = function()
					scheduler_b_active = true
				end,
				stop_scheduler = function()
					scheduler_b_active = false
				end,
			}

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(false)

			local initial_scheduler = ExternalScheduler.set_scheduler(scheduler_a)

			expect(scheduler_a_active):to_equal(true)
			expect(scheduler_b_active):to_equal(false)

			ExternalScheduler.set_scheduler(scheduler_b)

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(true)

			ExternalScheduler.set_scheduler(nil)

			expect(scheduler_a_active):to_equal(false)
			expect(scheduler_b_active):to_equal(false)

			ExternalScheduler.set_scheduler(initial_scheduler)
		end)
		test("task functions throw with no set scheduler", function()
			local initial_scheduler = ExternalScheduler.set_scheduler(nil)

			-- expect(ExternalScheduler.schedule_task_immediate):to_throw_with(external.missing_scheduler)
			expect(ExternalScheduler.schedule_task_delayed):to_throw_with(external.missing_scheduler)
			expect(ExternalScheduler.schedule_task_deferred):to_throw_with(external.missing_scheduler)
			-- expect(ExternalScheduler.cancel_task):to_throw_with(external.missing_scheduler)

			ExternalScheduler.set_scheduler(initial_scheduler)
		end)
		test("task functions call scheduler functions", function()
			local schedule_task_immediate_called = false
			local schedule_task_delayed_called = false
			local schedule_task_deferred_called = false
			local cancel_task_called = false

			local initial_scheduler = ExternalScheduler.set_scheduler({
				start_scheduler = function() end,
				stop_scheduler = function() end,
				schedule_task_immediate = function()
					schedule_task_immediate_called = true
				end,
				schedule_task_delayed = function()
					schedule_task_delayed_called = true
				end,
				schedule_task_deferred = function()
					schedule_task_deferred_called = true
				end,
				cancel_task = function()
					cancel_task_called = true
				end,
			})

			expect(schedule_task_immediate_called):to_equal(false)
			expect(schedule_task_delayed_called):to_equal(false)
			expect(schedule_task_deferred_called):to_equal(false)
			expect(cancel_task_called):to_equal(false)

			ExternalScheduler.schedule_task_immediate(nil :: any)
			ExternalScheduler.schedule_task_delayed(0, nil :: any)
			ExternalScheduler.schedule_task_deferred(nil :: any)
			ExternalScheduler.cancel_task(nil :: any)

			expect(schedule_task_immediate_called):to_equal(true)
			expect(schedule_task_delayed_called):to_equal(true)
			expect(schedule_task_deferred_called):to_equal(true)
			expect(cancel_task_called):to_equal(true)

			ExternalScheduler.set_scheduler(initial_scheduler)
		end)
		test("binding to and unbinding from update steps", function()
			local step = nil

			ExternalScheduler.set_scheduler({
				start_scheduler = function(s)
					step = s
				end,
				stop_scheduler = function()
					step = nil
				end,
			})

			local was_invoked = false
			local unbind = ExternalScheduler.bind_to_update_step(function(now: number)
				was_invoked = true
				expect(now):to_be_a("number")
			end)

			expect(was_invoked):to_equal(false)
			expect(unbind):to_be_a("function")

			-- ExternalScheduler.perform_update_step()
			step()

			expect(was_invoked):to_equal(true)

			was_invoked = false
			unbind()

			-- ExternalScheduler.perform_update_step()
			step()

			expect(was_invoked):to_equal(false)

			ExternalScheduler.set_scheduler(nil)
		end)
		test("get_last_update", function()
			local step = nil

			ExternalScheduler.set_scheduler({
				start_scheduler = function(s)
					step = s
				end,
				stop_scheduler = function()
					step = nil
				end,
			})

			local last_update = ExternalScheduler.get_last_update()
			-- ExternalScheduler.perform_update_step()
			step()

			expect(ExternalScheduler.get_last_update()):to_be_near(last_update, 0.001):to_be_greater_than(last_update)

			ExternalScheduler.set_scheduler(nil)
		end)
		test("get_delta_time", function()
			local step = nil

			ExternalScheduler.set_scheduler({
				start_scheduler = function(s)
					step = s
				end,
				stop_scheduler = function()
					step = nil
				end,
			})

			local last_update = ExternalScheduler.get_last_update()
			-- ExternalScheduler.perform_update_step()
			step()

			local now = ExternalScheduler.get_last_update()
			-- ExternalScheduler.perform_update_step()
			step()

			expect(ExternalScheduler.get_delta_time()):to_be_near(now - last_update, 0.001)

			ExternalScheduler.set_scheduler(nil)
		end)
	end)
end
