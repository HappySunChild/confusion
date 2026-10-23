const SpecTask = require("./SpecTask")

local active_stepper = nil

const SpecScheduler = {
	schedule_task_immediate = SpecTask.spawn,
	schedule_task_deferred = SpecTask.defer,
	schedule_task_delayed = SpecTask.delay,
	cancel_task = function(thread: thread)
		coroutine.close(thread)
	end,

	start_scheduler = function(step)
		active_stepper = step
	end,
	stop_scheduler = function()
		active_stepper = nil
	end,

	step = function()
		if active_stepper then
			active_stepper()
		end

		SpecTask.process()
	end,
}

return table.freeze(SpecScheduler)
