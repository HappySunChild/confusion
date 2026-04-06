local external = require("./types")

local log_error = require("../core_logging/log_error")

local bound_callbacks = {}
local active_scheduler: external.ExternalScheduler? = nil

local last_update = os.clock()
local delta_time = 0

return table.freeze({
	set_scheduler = function(new_scheduler: external.ExternalScheduler?)
		local old_scheduler = active_scheduler

		if old_scheduler ~= nil then
			old_scheduler.stop_scheduler()
		end

		if new_scheduler ~= nil then
			new_scheduler.start_scheduler()
		end

		active_scheduler = new_scheduler

		return old_scheduler
	end,

	do_task_immediate = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			log_error(external.missing_scheduler)
		end

		return active_scheduler.do_task_immediate(resume, ...)
	end,
	do_task_deferred = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			log_error(external.missing_scheduler)
		end

		return active_scheduler.do_task_deferred(resume, ...)
	end,
	do_task_delayed = function<A...>(sec: number, resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			log_error(external.missing_scheduler)
		end

		return active_scheduler.do_task_delayed(sec, resume, ...)
	end,
	cancel_task = function(task: thread): boolean
		if active_scheduler == nil then
			log_error(external.missing_scheduler)
		end

		return active_scheduler.cancel_task(task)
	end,

	bind_to_update_step = function(callback: (now: number, dt: number) -> ()): () -> ()
		local unique_identifier = {}
		bound_callbacks[unique_identifier] = callback

		return function()
			bound_callbacks[unique_identifier] = nil
		end
	end,
	perform_update_step = function(): ()
		local now = os.clock()

		delta_time = now - last_update
		last_update = now

		for _, callback in bound_callbacks do
			callback(now, delta_time)
		end
	end,

	get_delta_time = function(): number
		return delta_time
	end,
	get_last_update = function(): number
		return last_update
	end,
})
