local memory = require("../core_memory/types")

export type ExternalScheduler = {
	read start_scheduler: () -> (),
	read stop_scheduler: () -> (),

	read do_task_immediate: <A...>(resume: (A...) -> () | thread, A...) -> thread?,
	read do_task_deferred: <A...>(resume: (A...) -> () | thread, A...) -> thread?,
	read do_task_delayed: <A...>(sec: number, resume: (A...) -> () | thread, A...) -> thread?,
	read cancel_task: (task: thread) -> boolean,
}

export type ExternalDebugger = {
	read start_debugging: () -> (),
	read stop_debugging: () -> (),

	read track_scope: (scope: memory.Scope) -> (),
	read untrack_scope: (scope: memory.Scope) -> (),
}

export type ExternalLogger = {
	read log_error: (message: string) -> never,
	read log_error_nonfatal: (message: string) -> (),
	read log_warn: (message: string) -> (),
}

return {
	missing_provider = "ConFusion is not connected to an external provider.",
}
