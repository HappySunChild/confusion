local memory = require("../core_memory/types")

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
	log_error: (message: string, level: number?) -> never,
	log_error_nonfatal: (message: string) -> (),
	log_warn: (message: string) -> (),
}

return {
	missing_scheduler = "ConFusion is not connected to an external scheduler.",
}
