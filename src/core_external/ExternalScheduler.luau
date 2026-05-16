const external = require("./types")

const log_error = require("../core_logging/log_error")

const bound_callbacks = {}

local active_scheduler: external.ExternalScheduler? = nil
local active_do_task_immediate: (<A...>(resume: (A...) -> () | thread, A...) -> thread?)? = nil
local active_do_task_deferred: (<A...>(resume: (A...) -> () | thread, A...) -> thread?)? = nil
local active_do_task_delayed: (<A...>(sec: number, resume: (A...) -> () | thread, A...) -> thread?)? = nil
local active_cancel_task: ((task: thread) -> boolean)? = nil

local last_update_time = os.clock()
local delta_time = 0

return table.freeze({
	set_scheduler = function(new_scheduler: external.ExternalScheduler?)
		const old_scheduler = active_scheduler

		if old_scheduler ~= nil then
			old_scheduler.stop_scheduler()
		end

		if new_scheduler ~= nil then
			new_scheduler.start_scheduler()

			active_do_task_immediate = new_scheduler.do_task_immediate
			active_do_task_deferred = new_scheduler.do_task_deferred
			active_do_task_delayed = new_scheduler.do_task_delayed
			active_cancel_task = new_scheduler.cancel_task
		else
			active_do_task_immediate = nil
			active_do_task_deferred = nil
			active_do_task_delayed = nil
			active_cancel_task = nil
		end

		active_scheduler = new_scheduler

		return old_scheduler
	end,

	do_task_immediate = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			return log_error(external.missing_scheduler)
		end

		return active_do_task_immediate(resume, ...)
	end,
	do_task_deferred = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			return log_error(external.missing_scheduler)
		end

		return active_do_task_deferred(resume, ...)
	end,
	do_task_delayed = function<A...>(sec: number, resume: (A...) -> () | thread, ...: A...): thread?
		if active_scheduler == nil then
			return log_error(external.missing_scheduler)
		end

		return active_do_task_delayed(sec, resume, ...)
	end,
	cancel_task = function(task: thread): boolean
		if active_scheduler == nil then
			return log_error(external.missing_scheduler)
		end

		return active_cancel_task(task)
	end,

	bind_to_update_step = function(callback: (now: number, dt: number) -> ()): () -> ()
		const unique_identifier = {}
		bound_callbacks[unique_identifier] = callback

		return function()
			bound_callbacks[unique_identifier] = nil
		end
	end,
	perform_update_step = function(): ()
		const now = os.clock()

		delta_time = now - last_update_time
		last_update_time = now

		for _, callback in bound_callbacks do
			callback(now, delta_time)
		end
	end,

	get_delta_time = function(): number
		return delta_time
	end,
	get_last_update = function(): number
		return last_update_time
	end,
})
