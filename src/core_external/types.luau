const memory = require("../core_memory/types")
const logging = require("../core_logging/types")

export type ExternalScheduler = {
	start_scheduler: () -> (),
	stop_scheduler: () -> (),

	schedule_task_immediate: <A...>(resume: (A...) -> () | thread, A...) -> thread?,
	schedule_task_deferred: <A...>(resume: (A...) -> () | thread, A...) -> thread?,
	schedule_task_delayed: <A...>(sec: number, resume: (A...) -> () | thread, A...) -> thread?,
	cancel_task: (task: thread) -> boolean,
}

export type ExternalDebugger = {
	start_debugging: () -> (),
	stop_debugging: () -> (),

	track_scope: (scope: memory.Scope) -> (),
	untrack_scope: (scope: memory.Scope) -> (),

	begin_profile: (label: string) -> (),
	end_profile: () -> (),
}

export type ExternalLogger = {
	log_warn: (message: string, context: logging.LogContext?) -> (),
	log_error: (message: string, err: logging.Error | string?, context: logging.LogContext?) -> never,
	log_error_nonfatal: (message: string, err: logging.Error | string?, context: logging.LogContext?) -> (),
}

return {
	fallback_error = "External log_error callback should have thrown, but it didn't.",
	missing_scheduler = "confusion is not connected to an external scheduler.",
	yielded_with_no_scheduler = "A spawned thread yielded while not being connected to an external scheduler; the spawned thread will be frozen indefinitely.",
}
