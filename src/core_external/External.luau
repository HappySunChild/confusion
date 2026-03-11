local external = require("./types")

local log_error = require("../core_logging/log_error")

local bound_callbacks = {}
local active_provider: external.ExternalProvider? = nil

local last_update = os.clock()
local delta_time = 0

return table.freeze({
	set_provider = function(new_provider: external.ExternalProvider?)
		local old_provider = active_provider

		if old_provider ~= nil then
			old_provider.stop_scheduler()
		end

		if new_provider ~= nil then
			new_provider.start_scheduler()
		end

		active_provider = new_provider

		return old_provider
	end,
	bind_to_update_step = function(callback: (now: number) -> ()): () -> ()
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
			callback(now)
		end
	end,

	get_delta_time = function(): number
		return delta_time
	end,
	get_last_update = function(): number
		return last_update
	end,

	do_task_immediate = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_provider == nil then
			log_error(external.missing_provider)
		end

		return active_provider.do_task_immediate(resume, ...)
	end,
	do_task_deferred = function<A...>(resume: (A...) -> () | thread, ...: A...): thread?
		if active_provider == nil then
			log_error(external.missing_provider)
		end

		return active_provider.do_task_deferred(resume, ...)
	end,
	do_task_delayed = function<A...>(sec: number, resume: (A...) -> () | thread, ...: A...): thread?
		if active_provider == nil then
			log_error(external.missing_provider)
		end

		return active_provider.do_task_delayed(sec, resume, ...)
	end,
	cancel_task = function(task: thread): boolean
		if active_provider == nil then
			log_error(external.missing_provider)
		end

		return active_provider.cancel_task(task)
	end,
})
