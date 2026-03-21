local ExternalScheduler = require("@fusion/core_external/ExternalScheduler")

local SpecTask = require("./SpecTask")

local do_update_steps = false

local SpecScheduler = {
	do_task_immediate = SpecTask.spawn,
	do_task_deferred = SpecTask.defer,
	do_task_delayed = SpecTask.delay,
	cancel_task = function(thread: thread)
		coroutine.close(thread)
	end,

	start_scheduler = function()
		do_update_steps = true
	end,
	stop_scheduler = function()
		do_update_steps = false
	end,
	ext_step = function()
		if do_update_steps then
			ExternalScheduler.perform_update_step()
		end

		SpecTask.process()
	end,
}

return table.freeze(SpecScheduler)
