--!strict
--!native
--!optimize 2

const external = require("./types")

const ExternalLogger = require("./ExternalLogger")
const log_error = ExternalLogger.log_error
const log_warn = ExternalLogger.log_warn

const BOUND_CALLBACKS = {}

const function default_do_task_immediate<A...>(resume: (A...) -> () | thread, ...: A...): thread
	const thread: thread = if type(resume) == "thread" then resume else coroutine.create(resume)

	coroutine.resume(thread, ...)

	if coroutine.status(thread) == "suspended" then
		log_warn(external.scheduler_missing_spawn)
	end

	return thread
end

const function default_cancel_task(task: thread): boolean
	const success = coroutine.close(task)

	return success
end

local current_scheduler: external.ExternalScheduler? = nil
local current_do_task_immediate: <A...>(resume: (A...) -> () | thread, A...) -> thread? = default_do_task_immediate
local current_do_task_deferred: (<A...>(resume: (A...) -> () | thread, A...) -> thread?)? = nil
local current_do_task_delayed: (<A...>(sec: number, resume: (A...) -> () | thread, A...) -> thread?)? = nil
local current_cancel_task: (task: thread) -> boolean = default_cancel_task

local last_update_time = os.clock()
local delta_time = 0

const function perform_update_step()
	-- should confusion keep track of its own time, or be reliant on the external scheduler's time?
	-- if the need ever arises we can change this, but for now i think its good to keep things consistent
	const now = os.clock()

	delta_time = now - last_update_time
	last_update_time = now

	for _, callback in BOUND_CALLBACKS do
		callback(now, delta_time)
	end
end

const function bind_to_update_step(callback: (now: number, dt: number) -> ()): () -> ()
	const unique_identifier = {}
	BOUND_CALLBACKS[unique_identifier] = callback

	return function()
		BOUND_CALLBACKS[unique_identifier] = nil
	end
end

const function set_scheduler(new_scheduler: external.ExternalScheduler?)
	const old_scheduler = current_scheduler

	if old_scheduler ~= nil then
		old_scheduler.stop_scheduler()
	end

	if new_scheduler ~= nil then
		new_scheduler.start_scheduler(perform_update_step)

		current_do_task_immediate = new_scheduler.schedule_task_immediate or default_do_task_immediate
		current_do_task_deferred = new_scheduler.schedule_task_deferred
		current_do_task_delayed = new_scheduler.schedule_task_delayed
		current_cancel_task = new_scheduler.cancel_task or default_cancel_task
	else
		current_do_task_immediate = default_do_task_immediate
		current_do_task_deferred = nil
		current_do_task_delayed = nil
		current_cancel_task = default_cancel_task
	end

	current_scheduler = new_scheduler

	return old_scheduler
end

const function schedule_task_immediate<A...>(resume: (A...) -> () | thread, ...: A...): thread?
	return current_do_task_immediate(resume, ...)
end

const function schedule_task_deferred<A...>(resume: (A...) -> () | thread, ...: A...): thread?
	if current_scheduler == nil then
		return log_error(external.missing_scheduler)
	end

	if current_do_task_deferred == nil then
		return log_error(external.scheduler_missing_defer)
	end

	return current_do_task_deferred(resume, ...)
end

const function schedule_task_delayed<A...>(delay_sec: number, resume: (A...) -> () | thread, ...: A...): thread?
	if current_scheduler == nil then
		return log_error(external.missing_scheduler)
	end

	if current_do_task_delayed == nil then
		return log_error(external.scheduler_missing_delay)
	end

	return current_do_task_delayed(delay_sec, resume, ...)
end

const function cancel_task(task: thread): boolean
	return current_cancel_task(task)
end

const function get_delta_time(): number
	return delta_time
end

const function get_last_update(): number
	return last_update_time
end

return {
	set_scheduler = set_scheduler,

	schedule_task_immediate = schedule_task_immediate,
	schedule_task_deferred = schedule_task_deferred,
	schedule_task_delayed = schedule_task_delayed,
	cancel_task = cancel_task,

	bind_to_update_step = bind_to_update_step,
	get_delta_time = get_delta_time,
	get_last_update = get_last_update,
}
